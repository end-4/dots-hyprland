# EDITED.md — Changelog & Run Instructions

> **What to log:** Only changes **you** (omsenjalia) made — custom features, bug fixes, config tweaks, new modules.
> **What NOT to log:** Upstream syncs, end-4's commits, merge commits from `end-4:main`, community PRs (translations, CI, etc.). Those are tracked by git history already.

All changes relative to upstream `end-4/dots-hyprland`. Entries are in **reverse chronological order** (newest first).

---

## [NEW] System Settings App + Feature Modules

**Date:** 2026-03-30

### What changed

A comprehensive KDE/GNOME-style **System Settings** app (`SystemSettings.qml`) with a 3-column layout (categories → pages → content). It integrates both **system-level controls** (Display, Audio, Network, Bluetooth, Keyboard, Mouse, Power, Date & Time, Users) and the **existing dotfiles shell configurator** pages — all in one unified app.

Additionally, three new feature modules were added:
1. **Wallpaper Slideshow** — auto-rotate wallpapers from a folder on a timer
2. **YouTube Downloader** — download videos/audio via yt-dlp with queue + progress
3. **Quick Tools** — one-click system maintenance scripts (update packages, clear cache, etc.)

### Files affected

#### New services
- `ii/services/WallpaperSlideshow.qml` — Slideshow timer singleton, persists config
- `ii/services/YtDownloader.qml` — yt-dlp wrapper with queue management

#### New settings pages (dotfiles configurator tabs)
- `ii/modules/settings/WallpaperSlideshowConfig.qml` — slideshow toggle, interval, folder picker
- `ii/modules/settings/YtDownloaderConfig.qml` — download path, quality, format
- `ii/modules/settings/ToolsConfig.qml` — quick scripts (update, clean, reload)

#### New system settings pages (SystemSettings.qml)
- `ii/modules/sysSettings/DisplaySettings.qml` — monitors, brightness, compositor, night light
- `ii/modules/sysSettings/AudioSettings.qml` — volume, mute, device selection
- `ii/modules/sysSettings/NetworkSettings.qml` — Wi-Fi toggle, scan, network list
- `ii/modules/sysSettings/BluetoothSettings.qml` — on/off, manager link
- `ii/modules/sysSettings/DateTimeSettings.qml` — time/date format, pomodoro timer
- `ii/modules/sysSettings/UsersSettings.qml` — current user info, password change
- `ii/modules/sysSettings/KeyboardSettings.qml` — layout info, on-screen keyboard
- `ii/modules/sysSettings/MouseSettings.qml` — scroll settings, dead pixel workaround
- `ii/modules/sysSettings/PowerSettings.qml` — battery thresholds, suspend, lock screen

#### New panel modules
- `ii/modules/ii/YtDownloaderPanel.qml` — URL input + download queue with progress bars
- `ii/modules/ii/EmojiPickerPanel.qml` — fuzzy search emoji grid, copy on click

#### Modified files
- `ii/settings.qml` — added Slideshow, Downloader, Tools tabs to nav-rail
- `ii/shell.qml` — added `Emojis.load()` to startup
- `ii/SystemSettings.qml` — **new** main entry point for the full system settings app

### How to run

```bash
# Run the full System Settings app (KDE/GNOME-style with system + shell settings)
quickshell -p ~/.config/quickshell/ii/SystemSettings.qml

# Run the shell configurator only (original settings with new tabs)
quickshell -p ~/.config/quickshell/ii/settings.qml

# The slideshow and YT downloader services auto-load with the main shell:
quickshell  # (normal shell launch, services start automatically)
```

### Dependencies

```bash
# YouTube Downloader requires yt-dlp
yay -S yt-dlp

# Browse button in slideshow uses zenity (optional)
yay -S zenity

# Tools page scripts assume: yay, paccache, fastfetch, ncdu, btop (most already installed)
```


