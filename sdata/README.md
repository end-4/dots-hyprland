This folder mainly contains data for the script `setup`.

## Meta-Packages

The installation script uses meta-packages under `dist-arch/` to manage dependencies.
Each meta-package is a PKGBUILD that declares a list of dependencies.

### Custom Meta-Packages

| Package | Description |
|---------|-------------|
| `illogical-impulse-ghostty` | Ghostty terminal emulator (replaces kitty) |
| `illogical-impulse-personal` | Personal tools: zen-browser-bin, obsidian, zotero-bin, feishu-bin |

### Standard Meta-Packages

| Package | Description |
|---------|-------------|
| `illogical-impulse-basic` | Core utilities: bc, curl, jq, ripgrep, rsync, etc. |
| `illogical-impulse-hyprland` | Hyprland compositor |
| `illogical-impulse-audio` | Audio: cava, pavucontrol, wireplumber, playerctl |
| `illogical-impulse-backlight` | Brightness: brightnessctl, ddcutil, geoclue |
| `illogical-impulse-fonts-themes` | Themes: eza, matugen, starship, fonts |
| `illogical-impulse-kde` | KDE integration: dolphin, networkmanager |
| `illogical-impulse-portal` | XDG portals |
| `illogical-impulse-python` | Python environment (uv, gtk4) |
| `illogical-impulse-screencapture` | Screenshot: hyprshot, slurp, swappy |
| `illogical-impulse-toolkit` | Tools: wtype, ydotool |
| `illogical-impulse-widgets` | Widgets: hypridle, hyprlock, hyprpicker |
| `illogical-impulse-quickshell-git` | Quickshell desktop shell |

## Customization

To customize which packages are installed:

1. Edit `dist-arch/install-deps.sh` to add/remove meta-packages
2. Edit individual PKGBUILD files to add/remove specific dependencies

## Notes

- TODO: output the logs to a temp file, then show the path of the file so users will be able to read it again or upload it to issue.
- TODO: unify the message output via functions (for example `log_error`, `log_warning`).