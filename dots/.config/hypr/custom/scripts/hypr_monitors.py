#!/usr/bin/env python3
"""
hypr-monitors: Automated Display & Audio Manager for Hyprland
- Automatically detects external screens (HDMI/DisplayPort/TVs), adjusts 4K/HiDPI scaling & TV resolutions
- Clamshell Mode: Smart laptop lid switch handling (close lid -> external stays on; open lid -> restore)
- PipeWire Audio Routing for both OUTPUT (sinks: Speakers, HDMI/TV, Headset) & INPUT (sources: Mics)
- External Display DDC/CI Hardware Brightness Control (ddcutil)
- Night Light / Color Temperature control via hyprsunset
- DPMS Screen Standby / Sleep toggle
- Refresh Rate & FreeSync / VRR toggle
- Visual Display Arrangement support (Right, Left, Above, Mirror, Single)
- Real-time Hyprland socket2 event listener daemon
"""

import sys
import os
import re
import json
import time
import glob
import socket
import argparse
import subprocess
from pathlib import Path

CONFIG_DIR = Path.home() / ".config" / "hypr"
MONITORS_LUA = CONFIG_DIR / "monitors.lua"
STATE_FILE = CONFIG_DIR / "monitors_state.json"
PID_FILE = Path("/tmp") / f"hypr-monitors-{os.getuid()}.pid"

DEFAULT_STATE = {
    "mode": "extend-right",
    "ext_scale": 1.0,
    "ext_rate": "preferred",
    "ext_res": None,
    "vrr": False,
    "brightness": 80,
    "clamshell": False,
    "last_external": None,
    "custom_scales": {},
    "night_light": {"enabled": False, "temp": 4500}
}

def load_state():
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, "r") as f:
                data = json.load(f)
                return {**DEFAULT_STATE, **data}
        except Exception:
            pass
    return DEFAULT_STATE.copy()

def save_state(state):
    try:
        with open(STATE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    except Exception as e:
        print(f"Error saving state: {e}", file=sys.stderr)

def notify(title, message, icon="video-display", urgency="normal"):
    try:
        subprocess.run(
            ["notify-send", "-a", "Display Manager", "-i", icon, "-u", urgency, title, message],
            check=False
        )
    except Exception:
        pass

# --- AUDIO ROUTING (PipeWire / wpctl / pactl) ---

def get_audio_devices():
    sinks = []
    sources = []
    try:
        out = subprocess.check_output(["wpctl", "status"], timeout=3).decode("utf-8", errors="replace")
        current_section = None
        for line in out.splitlines():
            if "├─ Sinks:" in line or "│  ├─ Sinks:" in line:
                current_section = "sinks"
                continue
            elif "├─ Sources:" in line or "│  ├─ Sources:" in line:
                current_section = "sources"
                continue
            elif "├─ Filters:" in line or "├─ Devices:" in line or "└─ Streams:" in line or "Settings" in line:
                current_section = None
                continue

            if current_section in ("sinks", "sources"):
                m = re.search(r"([*]?)\s*(\d+)\.\s+(.+?)\s+\[vol:\s*([\d.]+)(\s*MUTED)?\]", line)
                if m:
                    is_active = bool(m.group(1))
                    dev_id = int(m.group(2))
                    name = m.group(3).strip()
                    vol = float(m.group(4))
                    muted = bool(m.group(5))
                    item = {
                        "id": dev_id,
                        "name": name,
                        "active": is_active,
                        "volume": int(vol * 100),
                        "muted": muted
                    }
                    if current_section == "sinks":
                        sinks.append(item)
                    else:
                        sources.append(item)
    except Exception as e:
        print(f"Error getting audio devices: {e}", file=sys.stderr)
    return {"sinks": sinks, "sources": sources}

def get_pactl_sink_map():
    sink_map = {}
    try:
        out = subprocess.check_output(["pactl", "list", "sinks"], timeout=2).decode("utf-8", errors="replace")
        cur_name = None
        for line in out.splitlines():
            line = line.strip()
            if line.startswith("Name: "):
                cur_name = line.split("Name: ", 1)[1].strip()
            elif line.startswith("Description: ") and cur_name:
                desc = line.split("Description: ", 1)[1].strip()
                sink_map[desc.lower()] = cur_name
    except Exception:
        pass
    return sink_map

def get_pactl_source_map():
    source_map = {}
    try:
        out = subprocess.check_output(["pactl", "list", "sources"], timeout=2).decode("utf-8", errors="replace")
        cur_name = None
        for line in out.splitlines():
            line = line.strip()
            if line.startswith("Name: "):
                cur_name = line.split("Name: ", 1)[1].strip()
            elif line.startswith("Description: ") and cur_name:
                desc = line.split("Description: ", 1)[1].strip()
                source_map[desc.lower()] = cur_name
    except Exception:
        pass
    return source_map

def set_audio_sink(target_id_or_name):
    devices = get_audio_devices()
    target_id = None
    target_name = ""

    # Check if target is an int ID
    try:
        t_id = int(target_id_or_name)
        for s in devices["sinks"]:
            if s["id"] == t_id:
                target_id = t_id
                target_name = s["name"]
                break
    except ValueError:
        kw = target_id_or_name.lower()
        if kw == "toggle":
            # Toggle between active sink and the other sink
            for s in devices["sinks"]:
                if not s["active"]:
                    target_id = s["id"]
                    target_name = s["name"]
                    break
        else:
            for s in devices["sinks"]:
                if kw in s["name"].lower():
                    target_id = s["id"]
                    target_name = s["name"]
                    break

    if target_id is not None:
        try:
            # 1. WirePlumber default
            subprocess.run(["wpctl", "set-default", str(target_id)], check=True, timeout=2)
            # 2. Automatically unmute
            subprocess.run(["wpctl", "set-mute", str(target_id), "0"], timeout=2)

            # 3. PulseAudio/pactl sync & move all active streams
            sink_map = get_pactl_sink_map()
            pactl_sink = sink_map.get(target_name.lower())
            if not pactl_sink:
                for d_name, p_name in sink_map.items():
                    if target_name.lower() in d_name or d_name in target_name.lower():
                        pactl_sink = p_name
                        break

            if pactl_sink:
                try:
                    subprocess.run(["pactl", "set-default-sink", pactl_sink], timeout=2)
                    sinp = subprocess.check_output(["pactl", "list", "short", "sink-inputs"], timeout=2).decode()
                    for line in sinp.strip().splitlines():
                        if line.strip():
                            inp_id = line.split()[0]
                            subprocess.run(["pactl", "move-sink-input", inp_id, pactl_sink], timeout=2)
                except Exception:
                    pass

            notify("🔊 Audio Output", f"Switched to {target_name}", icon="audio-speakers")
            return True
        except Exception as e:
            print(f"Error setting audio sink: {e}", file=sys.stderr)
    return False

def set_audio_source(target_id_or_name):
    devices = get_audio_devices()
    target_id = None
    target_name = ""

    try:
        t_id = int(target_id_or_name)
        for s in devices["sources"]:
            if s["id"] == t_id:
                target_id = t_id
                target_name = s["name"]
                break
    except ValueError:
        kw = target_id_or_name.lower()
        if kw == "toggle":
            for s in devices["sources"]:
                if not s["active"]:
                    target_id = s["id"]
                    target_name = s["name"]
                    break
        else:
            for s in devices["sources"]:
                if kw in s["name"].lower():
                    target_id = s["id"]
                    target_name = s["name"]
                    break

    if target_id is not None:
        try:
            # 1. WirePlumber default
            subprocess.run(["wpctl", "set-default", str(target_id)], check=True, timeout=2)
            # 2. Automatically unmute
            subprocess.run(["wpctl", "set-mute", str(target_id), "0"], timeout=2)

            # 3. PulseAudio/pactl sync & move all active recording streams
            src_map = get_pactl_source_map()
            pactl_src = src_map.get(target_name.lower())
            if not pactl_src:
                for d_name, p_name in src_map.items():
                    if target_name.lower() in d_name or d_name in target_name.lower():
                        pactl_src = p_name
                        break

            if pactl_src:
                try:
                    subprocess.run(["pactl", "set-default-source", pactl_src], timeout=2)
                    sout = subprocess.check_output(["pactl", "list", "short", "source-outputs"], timeout=2).decode()
                    for line in sout.strip().splitlines():
                        if line.strip():
                            out_id = line.split()[0]
                            subprocess.run(["pactl", "move-source-output", out_id, pactl_src], timeout=2)
                except Exception:
                    pass

            notify("🎙️ Microphone", f"Switched to {target_name}", icon="audio-input-microphone")
            return True
        except Exception as e:
            print(f"Error setting audio source: {e}", file=sys.stderr)
    return False

def set_audio_volume(target_id, percent):
    try:
        t_id = int(target_id)
        pct = max(0, min(150, int(percent)))
        subprocess.run(["wpctl", "set-volume", str(t_id), f"{pct}%"], check=True, timeout=2)
        return True
    except Exception as e:
        print(f"Error setting audio volume: {e}", file=sys.stderr)
        return False

def set_audio_mute(target_id):
    try:
        t_id = int(target_id)
        subprocess.run(["wpctl", "set-mute", str(t_id), "toggle"], check=True, timeout=2)
        return True
    except Exception as e:
        print(f"Error toggling audio mute: {e}", file=sys.stderr)
        return False

# --- DDC/CI & BRIGHTNESS ---

def get_current_brightness(has_external=False):
    state = load_state()
    if not has_external:
        try:
            out = subprocess.check_output(["brightnessctl", "-m"], timeout=1).decode().strip()
            parts = out.split(",")
            if len(parts) >= 4 and "%" in parts[3]:
                return int(parts[3].replace("%", ""))
        except Exception:
            pass
    return state.get("brightness", 80)

def set_external_brightness(val):
    val = max(0, min(100, int(val)))
    state = load_state()
    state["brightness"] = val
    save_state(state)
    # If external monitor exists, try ddcutil
    try:
        subprocess.Popen(
            ["ddcutil", "setvcp", "10", str(val)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        pass
    # Also adjust laptop screen via brightnessctl
    try:
        subprocess.Popen(
            ["brightnessctl", "set", f"{val}%"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
    except Exception:
        pass

# --- NIGHT LIGHT (hyprsunset) ---

def set_night_light(action_or_temp):
    state = load_state()
    nl = state.get("night_light", {"enabled": False, "temp": 4500})
    
    if action_or_temp in ("off", "identity"):
        nl["enabled"] = False
        subprocess.run(["hyprctl", "hyprsunset", "identity"], check=False)
        notify("🌙 Night Light", "Night Light turned OFF", icon="weather-clear-night")
    elif action_or_temp == "toggle":
        if nl.get("enabled"):
            nl["enabled"] = False
            subprocess.run(["hyprctl", "hyprsunset", "identity"], check=False)
            notify("🌙 Night Light", "Night Light turned OFF", icon="weather-clear-night")
        else:
            nl["enabled"] = True
            temp = nl.get("temp", 4500)
            subprocess.run(["hyprctl", "hyprsunset", "temperature", str(temp)], check=False)
            notify("🌙 Night Light", f"Night Light ON ({temp}K)", icon="weather-clear-night")
    else:
        try:
            temp = int(action_or_temp)
            temp = max(2500, min(6500, temp))
            nl["enabled"] = True
            nl["temp"] = temp
            subprocess.run(["hyprctl", "hyprsunset", "temperature", str(temp)], check=False)
        except ValueError:
            pass

    state["night_light"] = nl
    save_state(state)

# --- DPMS DISPLAY SLEEP / WAKE ---

def set_dpms(action, target_output=None):
    if not target_output:
        state = load_state()
        target_output = state.get("last_external")
        if not target_output:
            monitors = get_hyprland_monitors()
            _, externals = classify_monitors(monitors)
            if externals:
                target_output = externals[0].get("name")

    if not target_output:
        notify("Display Power", "No external display found to toggle power.")
        return False

    act_lua = "disable" if action == "off" else ("enable" if action == "on" else "toggle")
    cmd = f'hl.dsp.dpms({{ action = "{act_lua}", output = "{target_output}" }})'
    res = subprocess.run(["hyprctl", "dispatch", cmd], capture_output=True, text=True)
    if "ok" in res.stdout:
        notify("🖥️ Display Power", f"Display {target_output} signal {act_lua}d.")
        return True
    return False

# --- MONITOR CLASSIFICATION & DRM INSPECTION ---

def get_drm_info(port_name):
    info = {"name": None, "modes": [], "is_tv": False}
    for p in glob.glob(f"/sys/class/drm/*-{port_name}*"):
        edid_p = os.path.join(p, "edid")
        modes_p = os.path.join(p, "modes")
        if os.path.exists(edid_p):
            try:
                with open(edid_p, "rb") as f:
                    data = f.read()
                    matches = re.findall(b"\x00\x00\x00\xfc\x00([^\n\x00]+)", data)
                    if matches:
                        info["name"] = matches[0].decode("ascii", errors="ignore").strip()
            except Exception:
                pass
        if os.path.exists(modes_p):
            try:
                with open(modes_p, "r") as f:
                    info["modes"] = [l.strip() for l in f if l.strip()]
            except Exception:
                pass

    if info["name"] and any(tv_kw in info["name"].lower() for tv_kw in ["tv", "lg", "samsung", "bravia", "vizio", "tcl"]):
        info["is_tv"] = True
    elif info["modes"] and info["modes"][0] == "1360x768":
        info["is_tv"] = True

    return info

def get_hyprland_monitors():
    try:
        res = subprocess.check_output(["hyprctl", "monitors", "all", "-j"], timeout=3)
        return json.loads(res.decode("utf-8"))
    except Exception as e:
        print(f"Failed to query hyprctl monitors: {e}", file=sys.stderr)
        return []

def classify_monitors(monitors):
    internal = None
    externals = []
    
    for m in monitors:
        name = m.get("name", "")
        if name.startswith("eDP") or name.startswith("LVDS"):
            if internal is None or not m.get("disabled", False):
                internal = m
        elif not name.startswith("HEADLESS") or os.environ.get("HYPR_MONITORS_ALLOW_HEADLESS"):
            # Enrich with DRM hardware name
            drm_info = get_drm_info(name)
            if drm_info.get("name"):
                m["description"] = drm_info["name"]
            m["is_tv"] = drm_info.get("is_tv", False)
            m["drm_modes"] = drm_info.get("modes", [])
            externals.append(m)
            
    if internal is None and monitors:
        internal = monitors[0]
        externals = [m for m in monitors[1:] if not m.get("name", "").startswith("HEADLESS")]

    return internal, externals

def get_optimal_scale(mon, state):
    name = mon.get("name", "")
    if name in state.get("custom_scales", {}):
        return state["custom_scales"][name]

    width = mon.get("width", 1920)
    height = mon.get("height", 1080)
    
    if width >= 3840 or height >= 2160:
        return 1.5
    elif width >= 2560:
        return 1.25
    else:
        return 1.0

def build_lua_config(internal_mon, external_mons, mode, ext_scale, vrr=False, ext_rate="preferred", ext_res=None):
    lines = [
        "-- Generated automatically by hypr-monitors",
        "-- Custom adjustments can be changed via 'SUPER+P' or 'hypr-monitors menu'",
        ""
    ]
    
    int_name = internal_mon.get("name", "eDP-1") if internal_mon else "eDP-1"
    vrr_val = 1 if vrr else 0

    # Build mode string
    if ext_res and "@" in str(ext_res):
        mode_spec = ext_res
    elif ext_res:
        rate_part = f"@{ext_rate}" if ext_rate != "preferred" else "@60"
        mode_spec = f"{ext_res}{rate_part}"
    elif ext_rate and ext_rate != "preferred":
        mode_spec = f"preferred@{ext_rate}"
    else:
        mode_spec = "preferred"

    if mode == "second-only":
        lines.append(f'hl.monitor({{ output = "{int_name}", disabled = true }})')
        for ext in external_mons:
            e_name = ext.get("name", "")
            lines.append(f'hl.monitor({{ output = "{e_name}", mode = "{mode_spec}", position = "0x0", scale = {ext_scale}, vrr = {vrr_val} }})')
            
    elif mode == "laptop-only" or not external_mons:
        lines.append(f'hl.monitor({{ output = "{int_name}", mode = "preferred", position = "0x0", scale = 1, bitdepth = 8 }})')
        for ext in external_mons:
            e_name = ext.get("name", "")
            lines.append(f'hl.monitor({{ output = "{e_name}", disabled = true }})')
            
    elif mode == "mirror":
        lines.append(f'hl.monitor({{ output = "{int_name}", mode = "preferred", position = "0x0", scale = 1, bitdepth = 8 }})')
        for ext in external_mons:
            e_name = ext.get("name", "")
            lines.append(f'hl.monitor({{ output = "{e_name}", mode = "preferred", position = "auto", scale = 1, mirror = "{int_name}" }})')
            
    elif mode == "extend-left":
        for ext in external_mons:
            e_name = ext.get("name", "")
            lines.append(f'hl.monitor({{ output = "{e_name}", mode = "{mode_spec}", position = "0x0", scale = {ext_scale}, vrr = {vrr_val} }})')
        lines.append(f'hl.monitor({{ output = "{int_name}", mode = "preferred", position = "auto-right", scale = 1, bitdepth = 8 }})')
        
    elif mode == "extend-above":
        lines.append(f'hl.monitor({{ output = "{int_name}", mode = "preferred", position = "0x0", scale = 1, bitdepth = 8 }})')
        for ext in external_mons:
            e_name = ext.get("name", "")
            lines.append(f'hl.monitor({{ output = "{e_name}", mode = "{mode_spec}", position = "auto-up", scale = {ext_scale}, vrr = {vrr_val} }})')
            
    else:  # extend-right (default)
        lines.append(f'hl.monitor({{ output = "{int_name}", mode = "preferred", position = "0x0", scale = 1, bitdepth = 8 }})')
        for ext in external_mons:
            e_name = ext.get("name", "")
            lines.append(f'hl.monitor({{ output = "{e_name}", mode = "{mode_spec}", position = "auto-right", scale = {ext_scale}, vrr = {vrr_val} }})')
            
    return "\n".join(lines) + "\n"

def apply_configuration(mode, scale_override=None, notify_user=True, vrr_override=None, rate_override=None, res_override=None):
    state = load_state()
    monitors = get_hyprland_monitors()
    internal, externals = classify_monitors(monitors)
    
    if externals:
        primary_ext = externals[0]
        state["last_external"] = primary_ext.get("name")
        if scale_override is not None:
            ext_scale = float(scale_override)
            state["custom_scales"][primary_ext.get("name")] = ext_scale
        else:
            ext_scale = get_optimal_scale(primary_ext, state)
            
        # If it's a TV, default VRR to False unless explicitly overridden
        if primary_ext.get("is_tv") and vrr_override is None and "vrr" not in state:
            state["vrr"] = False
    else:
        ext_scale = 1.0

    if vrr_override is not None:
        state["vrr"] = bool(vrr_override)
    if rate_override is not None:
        state["ext_rate"] = str(rate_override)
    if res_override is not None:
        state["ext_res"] = str(res_override) if res_override != "auto" else None

    state["mode"] = mode
    state["ext_scale"] = ext_scale
    save_state(state)

    lua_code = build_lua_config(
        internal, externals, mode, ext_scale,
        vrr=state.get("vrr", False),
        ext_rate=state.get("ext_rate", "preferred"),
        ext_res=state.get("ext_res")
    )
    try:
        with open(MONITORS_LUA, "w") as f:
            f.write(lua_code)
    except Exception as e:
        print(f"Failed to write {MONITORS_LUA}: {e}", file=sys.stderr)
        return False

    try:
        subprocess.run(["hyprctl", "reload", "config-only"], check=True, timeout=3)
    except Exception as e:
        print(f"Failed to reload hyprctl: {e}", file=sys.stderr)
        return False

    if notify_user:
        mode_titles = {
            "extend-right": "Extend Display (Right)",
            "extend-left": "Extend Display (Left)",
            "extend-above": "Extend Display (Above)",
            "mirror": "Duplicate / Mirror",
            "second-only": "Second Screen Only",
            "laptop-only": "Laptop Screen Only"
        }
        title = mode_titles.get(mode, "Display Configured")
        if externals:
            ext = externals[0]
            ext_name = ext.get("description") or ext.get("name", "External Display")
            vrr_str = " • VRR Enabled" if state.get("vrr") else ""
            res_str = f" • {state.get('ext_res')}" if state.get('ext_res') else ""
            msg = f"{ext_name}\nMode: {mode}\nScale: {ext_scale}x{res_str}{vrr_str}"
        else:
            msg = f"Laptop screen active\nMode: {mode}"
        notify(f"🖥️ {title}", msg)

    return True

# --- CLAMSHELL / DOCK MODE (LID SWITCH) ---

def handle_lid_close():
    state = load_state()
    monitors = get_hyprland_monitors()
    internal, externals = classify_monitors(monitors)
    if externals:
        state["clamshell"] = True
        save_state(state)
        apply_configuration("second-only", notify_user=False)
        notify("💻 Clamshell Mode Active", "Laptop lid closed. Running on external screen.", icon="computer")
    else:
        subprocess.run(["systemctl", "suspend"], check=False)

def handle_lid_open():
    state = load_state()
    monitors = get_hyprland_monitors()
    internal, externals = classify_monitors(monitors)
    if state.get("clamshell"):
        state["clamshell"] = False
        save_state(state)
        if externals:
            apply_configuration("extend-right", notify_user=False)
            notify("💻 Laptop Screen Restored", "Laptop lid opened. Restored extend display.", icon="computer")
        else:
            apply_configuration("laptop-only", notify_user=False)

# --- AUTO-DETECTION ---

def auto_detect(notify_user=True):
    state = load_state()
    monitors = get_hyprland_monitors()
    internal, externals = classify_monitors(monitors)

    if not externals:
        apply_configuration("laptop-only", notify_user=notify_user)
        return

    primary_ext = externals[0]
    name = primary_ext.get("name", "HDMI")
    desc = primary_ext.get("description") or name
    width = primary_ext.get("width", 1920)
    height = primary_ext.get("height", 1080)
    rate = primary_ext.get("refreshRate", 60.0)

    # Smart default for TV: disable VRR to prevent flicker/tearing
    if primary_ext.get("is_tv"):
        state["vrr"] = False

    scale = get_optimal_scale(primary_ext, state)
    mode = state.get("mode", "extend-right")
    if mode == "laptop-only":
        mode = "extend-right"

    apply_configuration(mode, scale_override=scale, notify_user=False)
    
    # Auto-switch audio if HDMI sink exists
    audio_info = get_audio_devices()
    for sink in audio_info.get("sinks", []):
        if "hdmi" in sink["name"].lower() or "digital stereo" in sink["name"].lower():
            set_audio_sink(sink["id"])
            break

    if notify_user:
        scale_label = f"{scale}x"
        is_4k = " (4K UHD Detected!)" if (width >= 3840 or height >= 2160) else ""
        tv_tag = " (TV Detected)" if primary_ext.get("is_tv") else ""
        notify(
            f"🖥️ External Display Connected{is_4k}{tv_tag}",
            f"{desc} ({width}x{height} @ {rate:.0f}Hz)\nMode: {mode}\nScale: {scale_label}"
        )

# --- EXPORT JSON FOR UI ---

def export_json():
    state = load_state()
    monitors = get_hyprland_monitors()
    internal, externals = classify_monitors(monitors)
    audio = get_audio_devices()

    ext_data = None
    if externals:
        e = externals[0]
        # Parse available rates and resolutions
        rates = set()
        resolutions = set()
        for m_str in e.get("availableModes", []):
            if "@" in m_str:
                parts = m_str.split("@")
                res_part = parts[0]
                rate_part = parts[1].replace("Hz", "")
                resolutions.add(res_part)
                try:
                    rates.add(round(float(rate_part)))
                except ValueError:
                    pass

        # If DRM modes exist, add them
        for dm in e.get("drm_modes", []):
            resolutions.add(dm)

        ext_data = {
            "name": e.get("name"),
            "description": e.get("description") or e.get("name"),
            "width": e.get("width"),
            "height": e.get("height"),
            "rate": round(e.get("refreshRate", 60)),
            "scale": e.get("scale", 1.0),
            "disabled": e.get("disabled", False),
            "dpms": e.get("dpmsStatus", True),
            "vrr": e.get("vrr", False),
            "is_tv": e.get("is_tv", False),
            "is_4k": (e.get("width", 0) >= 3840 or e.get("height", 0) >= 2160),
            "available_rates": sorted(list(rates), reverse=True)[:6],
            "available_resolutions": sorted(list(resolutions), key=lambda x: int(x.split('x')[0]) if 'x' in x else 0, reverse=True)[:6]
        }

    int_data = None
    if internal:
        int_data = {
            "name": internal.get("name"),
            "description": internal.get("description") or internal.get("name"),
            "width": internal.get("width"),
            "height": internal.get("height"),
            "rate": round(internal.get("refreshRate", 60)),
            "scale": internal.get("scale", 1.0),
            "disabled": internal.get("disabled", False)
        }

    data = {
        "has_external": len(externals) > 0,
        "internal": int_data,
        "external": ext_data,
        "mode": state.get("mode", "extend-right"),
        "ext_scale": state.get("ext_scale", 1.0),
        "ext_rate": state.get("ext_rate", "preferred"),
        "ext_res": state.get("ext_res"),
        "vrr": state.get("vrr", False),
        "brightness": get_current_brightness(len(externals) > 0),
        "night_light": state.get("night_light", {"enabled": False, "temp": 4500}),
        "sinks": audio.get("sinks", []),
        "sources": audio.get("sources", [])
    }
    print(json.dumps(data))

# --- UI LAUNCHER ---

def show_menu(prefer_gui=True):
    toggle_script = Path(__file__).parent / "project-display-toggle.sh"
    if prefer_gui and toggle_script.exists():
        subprocess.run([str(toggle_script)])
        return
    apply_configuration("extend-right")

# --- BACKGROUND DAEMON ---

def run_daemon():
    if PID_FILE.exists():
        try:
            with open(PID_FILE, "r") as f:
                old_pid = int(f.read().strip())
            os.kill(old_pid, 0)
            print(f"hypr-monitors daemon is already running (pid {old_pid}). Exiting.")
            sys.exit(0)
        except (ProcessLookupError, ValueError):
            pass
        except PermissionError:
            print("Another instance is running under different permissions.")
            sys.exit(1)

    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))

    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    xdg = os.environ.get("XDG_RUNTIME_DIR")
    if not sig or not xdg:
        print("HYPRLAND_INSTANCE_SIGNATURE or XDG_RUNTIME_DIR not set.", file=sys.stderr)
        sys.exit(1)

    sock_path = os.path.join(xdg, "hypr", sig, ".socket2.sock")
    print(f"Connecting to Hyprland event socket: {sock_path}")

    try:
        auto_detect(notify_user=False)
    except Exception as e:
        print(f"Initial auto_detect failed: {e}", file=sys.stderr)

    while True:
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(sock_path)
            f = s.makefile("r", encoding="utf-8", errors="replace")
            print("hypr-monitors daemon listening for monitor events...")

            for line in f:
                line = line.strip()
                if not line:
                    continue

                if line.startswith("monitoradded>>") or line.startswith("monitoraddedv2>>"):
                    print(f"Event received: {line}")
                    time.sleep(0.6)
                    auto_detect(notify_user=True)

                elif line.startswith("monitorremoved>>"):
                    print(f"Event received: {line}")
                    time.sleep(0.4)
                    monitors = get_hyprland_monitors()
                    _, externals = classify_monitors(monitors)
                    if not externals:
                        print("All external monitors removed, restoring laptop display.")
                        apply_configuration("laptop-only", notify_user=True)

        except Exception as e:
            print(f"Socket connection lost ({e}). Reconnecting in 3s...", file=sys.stderr)
            time.sleep(3)

def print_status():
    state = load_state()
    monitors = get_hyprland_monitors()
    internal, externals = classify_monitors(monitors)

    print("=== Hyprland Monitor Status ===")
    print(f"Internal Display: {internal.get('name') if internal else 'None'}")
    if internal:
        print(f"  Resolution: {internal.get('width')}x{internal.get('height')} @ {internal.get('refreshRate', 0):.1f}Hz")
        print(f"  Scale: {internal.get('scale')}, Disabled: {internal.get('disabled')}")

    print(f"\nExternal Displays ({len(externals)}):")
    for ext in externals:
        desc = ext.get("description") or ext.get("name")
        w, h = ext.get("width"), ext.get("height")
        rate = ext.get("refreshRate", 0)
        is_4k = " [4K UHD]" if (w >= 3840 or h >= 2160) else ""
        tv_tag = " [TV Mode]" if ext.get("is_tv") else ""
        print(f"  • {desc} ({ext.get('name')}): {w}x{h} @ {rate:.1f}Hz{is_4k}{tv_tag}")
        print(f"    Scale: {ext.get('scale')}, Disabled: {ext.get('disabled')}")

    print("\nSaved Configuration:")
    print(f"  Current Mode: {state.get('mode')}")
    print(f"  External Scale: {state.get('ext_scale')}x")
    print(f"  External Resolution: {state.get('ext_res') or 'Auto'}")
    print(f"  Refresh Rate Mode: {state.get('ext_rate')}")
    print(f"  VRR / FreeSync: {state.get('vrr')}")
    print(f"  Brightness (DDC/CI): {state.get('brightness')}%")
    print(f"  Night Light: {state.get('night_light')}")
    print(f"  Clamshell Active: {state.get('clamshell')}")

def main():
    parser = argparse.ArgumentParser(description="Hyprland Display & Audio Manager")
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("gui", help="Open Project Display flyout (Super+P)")
    subparsers.add_parser("menu", help="Open display switcher flyout")
    subparsers.add_parser("daemon", help="Run background monitor detection daemon")
    subparsers.add_parser("auto", help="Auto-detect and configure connected displays")
    subparsers.add_parser("status", help="Print current display status")
    subparsers.add_parser("json", help="Export full display & audio state as JSON")
    subparsers.add_parser("lid-close", help="Handle laptop lid close (Clamshell mode)")
    subparsers.add_parser("lid-open", help="Handle laptop lid open")

    p_mode = subparsers.add_parser("mode", help="Apply a specific display mode")
    p_mode.add_argument("mode_name", choices=["extend-right", "extend-left", "extend-above", "mirror", "second-only", "laptop-only"])
    p_mode.add_argument("--scale", type=float, default=None, help="Override external screen scale")

    p_scale = subparsers.add_parser("scale", help="Set external display scaling")
    p_scale.add_argument("scale_val", type=float, help="Scale factor (e.g. 1.0, 1.25, 1.5, 2.0)")

    p_res = subparsers.add_parser("res", help="Set external display resolution")
    p_res.add_argument("res_val", help="Resolution (e.g. 1360x768, 1920x1080, auto)")

    p_vrr = subparsers.add_parser("vrr", help="Toggle or set VRR (FreeSync)")
    p_vrr.add_argument("vrr_state", choices=["on", "off", "toggle"])

    p_rate = subparsers.add_parser("rate", help="Set external display refresh rate")
    p_rate.add_argument("rate_val", help="Refresh rate (e.g. 60, 75, 100, 144, preferred)")

    p_bright = subparsers.add_parser("brightness", help="Set external display hardware brightness (DDC/CI)")
    p_bright.add_argument("percent", type=int, help="Brightness percentage 0-100")

    p_sunset = subparsers.add_parser("sunset", help="Control Night Light warmth via hyprsunset")
    p_sunset.add_argument("temp_or_action", help="Temperature in K (e.g. 4500) or 'off' / 'toggle'")

    p_dpms = subparsers.add_parser("dpms", help="Sleep or wake external display")
    p_dpms.add_argument("action", choices=["toggle", "off", "on"])
    p_dpms.add_argument("--output", default=None, help="Specific output name")

    p_asink = subparsers.add_parser("audio-sink", help="Set audio output device")
    p_asink.add_argument("target", help="Device ID, name substring (e.g. hdmi, speakers), or 'toggle'")

    p_asrc = subparsers.add_parser("audio-source", help="Set audio input / microphone")
    p_asrc.add_argument("target", help="Device ID, name substring, or 'toggle'")

    p_avol = subparsers.add_parser("audio-volume", help="Set audio device volume")
    p_avol.add_argument("target_id", help="Device ID")
    p_avol.add_argument("percent", type=int, help="Volume percentage (0-150)")

    p_amute = subparsers.add_parser("audio-mute", help="Toggle audio device mute")
    p_amute.add_argument("target_id", help="Device ID")

    args = parser.parse_args()

    if args.command in ("gui", "menu") or args.command is None:
        show_menu(prefer_gui=True)
    elif args.command == "daemon":
        run_daemon()
    elif args.command == "auto":
        auto_detect(notify_user=True)
    elif args.command == "status":
        print_status()
    elif args.command == "json":
        export_json()
    elif args.command == "lid-close":
        handle_lid_close()
    elif args.command == "lid-open":
        handle_lid_open()
    elif args.command == "mode":
        apply_configuration(args.mode_name, scale_override=args.scale)
    elif args.command == "scale":
        apply_configuration(load_state().get("mode", "extend-right"), scale_override=args.scale_val)
    elif args.command == "res":
        apply_configuration(load_state().get("mode", "extend-right"), res_override=args.res_val)
    elif args.command == "rate":
        apply_configuration(load_state().get("mode", "extend-right"), rate_override=args.rate_val)
    elif args.command == "vrr":
        curr = load_state().get("vrr", False)
        new_vrr = not curr if args.vrr_state == "toggle" else (args.vrr_state == "on")
        apply_configuration(load_state().get("mode", "extend-right"), vrr_override=new_vrr)
    elif args.command == "brightness":
        set_external_brightness(args.percent)
    elif args.command == "sunset":
        set_night_light(args.temp_or_action)
    elif args.command == "dpms":
        set_dpms(args.action, target_output=args.output)
    elif args.command == "audio-sink":
        set_audio_sink(args.target)
    elif args.command == "audio-source":
        set_audio_source(args.target)
    elif args.command == "audio-volume":
        set_audio_volume(args.target_id, args.percent)
    elif args.command == "audio-mute":
        set_audio_mute(args.target_id)

if __name__ == "__main__":
    main()
