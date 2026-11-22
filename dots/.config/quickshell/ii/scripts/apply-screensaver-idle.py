#!/usr/bin/env python3
"""Sync hypridle.conf (screensaver, lock, DPMS, suspend) from illogical-impulse config.json."""

import json
import os
import subprocess

CONFIG_JSON = os.path.expanduser("~/.config/illogical-impulse/config.json")
HYPRIDLE_CONF = os.path.expanduser("~/.config/hypr/hypridle.conf")


def main() -> int:
    cfg = {}
    if os.path.exists(CONFIG_JSON):
        try:
            with open(CONFIG_JSON, encoding="utf-8") as f:
                cfg = json.load(f)
        except Exception:
            cfg = {}

    ss = cfg.get("screensaver", {})
    idle = cfg.get("lock", {}).get("idle", {})

    ss_en = bool(ss.get("enable", False))
    ss_min = max(1, min(60, int(ss.get("timeoutMinutes", 3))))

    lock_en = bool(idle.get("enableLock", True))
    lock_min = max(1, min(120, int(idle.get("lockMinutes", 5))))

    dpms_en = bool(idle.get("enableDpms", True))
    dpms_min = max(1, min(180, int(idle.get("dpmsMinutes", 10))))

    susp_en = bool(idle.get("enableSuspend", False))
    susp_min = max(5, min(360, int(idle.get("suspendMinutes", 15))))

    lines = [
        "$lock_cmd = hyprctl dispatch 'hl.dsp.global(\"quickshell:lock\")' & pidof qs quickshell hyprlock || hyprlock\n",
        "$suspend_cmd = systemctl suspend || loginctl suspend\n\n",
        "general {\n",
        "    lock_cmd = $lock_cmd\n",
        "    before_sleep_cmd = loginctl lock-session\n",
        "    after_sleep_cmd = hyprctl dispatch 'hl.dsp.global(\"quickshell:lockFocus\")'\n",
        "    inhibit_sleep = 3\n",
        "}\n",
    ]

    if ss_en:
        lines += [
            f"\nlistener {{\n    timeout = {ss_min * 60}\n",
            "    on-timeout = qs -c ii ipc call screensaver open\n",
            "    on-resume = qs -c ii ipc call screensaver close\n}\n",
        ]
    if lock_en:
        lines += [
            f"\nlistener {{\n    timeout = {lock_min * 60}\n",
            "    on-timeout = qs -c ii ipc call screensaver armLock || loginctl lock-session\n}\n",
        ]
    if dpms_en:
        lines += [
            f"\nlistener {{\n    timeout = {dpms_min * 60}\n",
            "    on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'\n",
            "    on-resume = hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'\n}\n",
        ]
    if susp_en:
        lines += [
            f"\nlistener {{\n    timeout = {susp_min * 60}\n",
            "    on-timeout = $suspend_cmd\n}\n",
        ]

    os.makedirs(os.path.dirname(HYPRIDLE_CONF), exist_ok=True)
    with open(HYPRIDLE_CONF, "w", encoding="utf-8") as f:
        f.writelines(lines)

    if subprocess.run(["pgrep", "-x", "hypridle"], stdout=subprocess.DEVNULL).returncode == 0:
        subprocess.run(["pkill", "-x", "hypridle"], check=False)
        subprocess.Popen(["hypridle"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
