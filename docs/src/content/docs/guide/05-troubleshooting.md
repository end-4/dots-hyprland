---
title: Troubleshooting
description: Common issues and debug commands for dots-hyprland
---

## Quickshell

### Quickshell not starting

Check the virtual environment is set:
```bash
echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV
# Should output: $HOME/.local/state/quickshell/.venv
```

Run manually to see errors:
```bash
qs -c ii
```

Verify the submap is initialized (required for keybinds):
```bash
hyprctl dispatch submap global
```

### Quickshell alive check

```bash
qs -c ii ipc call TEST_ALIVE
# Returns 0 if running, non-zero if not
```

### Restart Quickshell

```bash
killall ydotool qs quickshell; qs -c ii &
# Or use: Ctrl + Super + R
```

## Colors

### Colors not updating

1. Ensure `matugen-bin` is installed:
   ```bash
   pacman -Qs matugen
   ```

2. Check wallpaper path is valid:
   ```bash
   ls -la "$(cat ~/.config/quickshell/ii/config.json | jq -r '.wallpaper // empty')"
   ```

3. Regenerate manually:
   ```bash
   ~/.config/quickshell/ii/scripts/colors/switchwall.sh /path/to/wallpaper.png
   ```

## Panel family

### Panel family not switching

- Ensure the shortcut is bound: `Ctrl + Super + P` or `Super + W`
- Check the current value:
  ```bash
  qs -c ii ipc call panelFamily get
  ```
- Valid values are `ii` and `waffle`
- Restart Quickshell after changes

## Power profiles

### Fn+Q not working

1. Check if your key maps to `XF86Launch4`:
   ```bash
   wev
   # Press Fn+Q and look for the key name
   ```

2. If it maps differently, edit `~/.config/hypr/custom/keybinds.lua`:
   ```lua
   -- Replace XF86Launch4 with your key name
   hl.bind("", "YOUR_KEY_NAME", hl.dsp.exec_cmd("qs ipc call powerProfile cycle"))
   ```

3. Ensure `power-profiles-daemon` is running:
   ```bash
   systemctl status power-profiles-daemon
   ```

## Audio

### No audio in screen recordings

Install `wf-recorder` with audio support and check for monitor sources:
```bash
pactl list sources | grep -i monitor
```

### Volume controls not working

Check `wpctl` is available:
```bash
wpctl status
wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%
```

## WiFi

### WiFi status flickering

If you have a MediaTek MT7921 (or similar) that creates a virtual `wifi-p2p` device, the network service may flicker. This fork includes a fix that excludes `wifi-p2p` devices from status detection.

Verify your devices:
```bash
nmcli -t -f TYPE,STATE d status
# "wifi-p2p:disconnected" should NOT affect the status icon
```

## Screen recording

### Recording fails silently

Check `wf-recorder` is installed and the save directory exists:
```bash
which wf-recorder
ls -la ~/Videos/  # Default save location
```

## Merge conflicts with upstream

When syncing with upstream (especially after major changes like the Lua migration):

1. Backup your custom configs:
   ```bash
   cp -r ~/.config/hypr/custom/ /tmp/custom-backup/
   ```

2. Fetch and merge:
   ```bash
   git fetch upstream
   git merge upstream/main
   ```

3. For modify/delete conflicts on `.conf` files:
   - Accept the upstream deletion (`.conf` → `.lua` migration)
   - Port your customizations to the new `.lua` format
   - See the [Configuration guide](/guide/04-configuration/) for the Lua API reference

## Debug commands

```bash
# Check Quickshell
qs -c ii ipc call TEST_ALIVE

# Check services
systemctl --user status ydotool
systemctl status bluetooth
systemctl status power-profiles-daemon

# Check environment
echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV
echo $XDG_CONFIG_HOME

# Regenerate colors
~/.config/quickshell/ii/scripts/colors/switchwall.sh /path/to/wallpaper

# Reset first-run wizard
./setup resetfirstrun

# Check Hyprland version and plugins
hyprctl version
hyprpm list
```
