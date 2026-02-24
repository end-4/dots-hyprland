# dots-hyprland — Custom Configs

> **Branch**: `feature/homeassistant-integration`  
> **Based on**: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)

Personalized customizations for Hyprland + QuickShell (illogical-impulse).

## 🏠 Home Assistant Integration (Quickshell)

This branch adds a HomeKit-style Home Assistant panel to the top bar.

### What it does

- Adds a `home` icon in the bar.
- Opens a Home panel with grouped devices:
  - Cameras (top row)
  - Security & Access
  - Lighting
  - Climate & Appliances
- Supports:
  - Toggle actions for lights/switches/locks/covers/climate
  - Brightness slider for dimmable devices
  - Camera click opens PiP live stream (via `mpv`), with fallback

### Privacy-safe configuration

Personal setup is now expected in an external file outside the repo:

- Default path: `~/.config/illogical-impulse/homeassistant.json`
- Optional override in settings:
  - `Services -> Home Assistant -> External config path`

This keeps personal entity names and tokens out of git-tracked config.

### External config format

```json
{
  "url": "https://your-home.ui.nabu.casa",
  "token": "YOUR_LONG_LIVED_ACCESS_TOKEN",
  "fetchInterval": 15,

  "cameras": ["camera.front_door"],
  "lights": ["light.living_room"],
  "locks": ["lock.front_door"],
  "covers": ["cover.garage"],
  "climate": ["climate.main"],
  "appliances": ["switch.coffee_maker"]
}
```

`fetchInterval` is in minutes.

### Notes

- If `url` omits scheme, `https://` is auto-added.
- If `mpv` is installed, camera tiles open an always-on-top PiP window.
- If external config is missing, shell settings values are used as fallback.

## ⌨️ Custom Keybindings

**File**: `dots/.config/hypr/custom/keybinds.conf`

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Super + Z` | Voice typing | Triggers voice-to-text via IPC |
| `Super + Alt + D` | Docker toggle | Starts/stops Docker daemon (polkit GUI auth) |
| `Super + Alt + B` | Bluetui | Opens Bluetooth TUI manager |
| `Super + Alt + V` | VPN toggle | Toggles VPN connection (polkit GUI auth) |
| `Super + Shift + [0-9]` | Move to Workspace | Moves active window to workspace 1-9 |
| `Super + Alt + →/←` | Next/Prev Workspace | Switches workspace on current monitor |

## 🕐 Date Format (US-style)

**File**: `dots/.config/quickshell/ii/modules/common/Config.qml`

Changes date display from `dd/MM` (European) to `MM/dd` (US):

| Format | Default | Custom |
|--------|---------|--------|
| Top bar date | `ddd, dd/MM` | `ddd, MM/dd` |
| Short date | `dd/MM` | `MM/dd` |
| Date with year | `dd/MM/yyyy` | `MM/dd/yyyy` |

> **Note**: QuickShell persists user settings to `~/.config/illogical-impulse/config.json`.  
> Changes to `Config.qml` only set defaults — the JSON file overrides them.  
> To apply: update both the QML file and the `time` section in `config.json`.

## � Polkit (GUI Auth with Fingerprint)

The Docker toggle uses `pkexec` instead of `sudo`, showing a GUI auth dialog that supports fingerprint + password.

### Fingerprint support

Put `pam_fprintd.so` before `pam_unix.so` in `/etc/pam.d/polkit-1`:

```
#%PAM-1.0
auth            sufficient      pam_fprintd.so
auth            sufficient      pam_unix.so try_first_pass likeauth nullok
auth            include         system-auth
account         include         system-auth
session         include         system-auth
```

### Disable auth chime

Create `~/.local/share/knotifications6/polkit-kde-authentication-agent-1.notifyrc`:

```ini
[Event/authenticate]
Action=
```

Then restart the agent: `killall polkit-kde-authentication-agent-1 && /usr/lib/polkit-kde-authentication-agent-1 &`

## �📦 Installation

```bash
# Sync keybinds
cp dots/.config/hypr/custom/keybinds.conf ~/.config/hypr/custom/
cp dots/.config/hypr/custom/scripts/*.sh ~/.config/hypr/custom/scripts/

# Sync QuickShell config
rsync -av dots/.config/quickshell/ii/modules/common/Config.qml \
  ~/.config/quickshell/ii/modules/common/Config.qml

# Update persisted QuickShell settings
python3 -c "
import json
p = '$HOME/.config/illogical-impulse/config.json'
with open(p) as f: d = json.load(f)
d['time']['dateFormat'] = 'ddd, MM/dd'
d['time']['shortDateFormat'] = 'MM/dd'
d['time']['dateWithYearFormat'] = 'MM/dd/yyyy'
with open(p, 'w') as f: json.dump(d, f, indent=2)
"
```

## Dependencies

- `kitty` — Terminal emulator
- `bluetui` — Bluetooth TUI (optional)
- VPN toggle script at `~/Documents/vpn-toggle.sh` (optional)

---

**Original Repository**: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)  
**Customization by**: tslove923
