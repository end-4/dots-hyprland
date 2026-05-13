---
title: Usage
description: Daily usage guide — keybinds, panel families, sidebars, and fork-specific features
---

## Keybinds

### Shell controls

| Keybind | Action |
|---------|--------|
| `Super` (tap) | Toggle app launcher / search |
| `Super + Tab` | Window overview with drag-and-drop |
| `Super + A` | Toggle left sidebar (AI chat, utilities) |
| `Super + N` | Toggle right sidebar (notifications, calendar) |
| `Super + V` | Clipboard history |
| `Super + .` | Emoji picker |
| `Super + Slash` | Cheatsheet (shows all keybinds) |
| `Super + K` | On-screen keyboard |
| `Super + M` | Media controls |
| `Super + G` | Widget overlay |
| `Super + J` | Toggle bar |
| `Ctrl + Super + P` | Cycle panel family (ii ↔ waffle) |

### Fork-specific keybinds

| Keybind | Action |
|---------|--------|
| `Super + W` | Cycle panel family |
| `Super + B` | Launch browser (tries Chrome, Zen, Firefox, Brave, etc.) |
| `Super + Space` | Launch Ollama Claude |
| `Ctrl + Super + S` | Toggle special workspace (scratchpad) |
| `Ctrl + Super + Slash` | Edit shell config (`config.json`) |
| `Ctrl + Super + Alt + Slash` | Edit custom keybinds (`keybinds.lua`) |
| `Fn + Q` (`XF86Launch4`) | Cycle power profile |

### Window management

| Keybind | Action |
|---------|--------|
| `Super + Q` | Close window |
| `Super + D` | Maximize |
| `Super + F` | Fullscreen |
| `Super + Alt + Space` | Toggle floating |
| `Super + P` | Pin window |
| `Super + Arrow keys` | Focus in direction |
| `Super + Shift + Arrow keys` | Move window in direction |
| `Super + 1-9` | Switch to workspace |
| `Super + Alt + 1-9` | Send window to workspace |
| `Super + S` | Toggle scratchpad |
| `Super + L` | Lock screen |

### Utilities

| Keybind | Action |
|---------|--------|
| `Super + Shift + S` | Region screenshot |
| `Super + Shift + A` | Google Lens (screen search) |
| `Super + Shift + X` | OCR to clipboard |
| `Super + Shift + C` | Color picker |
| `Super + Shift + R` | Record screen region |
| `Print` | Screenshot to clipboard |

## Panel families

The shell includes two panel families that can be cycled with `Ctrl + Super + P` or `Super + W`:

### ii (default)
The illogical-impulse style with a top bar, left/right sidebars, overview, and floating overlays.

### waffle
A Windows 11-inspired layout with a bottom taskbar, start menu, and action center. Currently a work-in-progress.

You can also switch via IPC:
```bash
qs -c ii ipc call panelFamily cycle
```

## System Settings

Launch the unified settings app:
```bash
# Full system settings (KDE/GNOME-style)
qs -p ~/.config/quickshell/ii/SystemSettings.qml

# Or use the keybind:
# Super + I
```

This app includes pages for Display, Audio, Network, Bluetooth, Keyboard, Mouse, Power, Date & Time, and Users — plus the original shell configurator tabs (Wallpaper Slideshow, YT Downloader, Quick Tools).

## Power profiles

Cycle with `Fn + Q` or via IPC:

```bash
# Cycle through profiles
qs ipc call powerProfile cycle

# Set directly
qs ipc call powerProfile set balanced
qs ipc call powerProfile set performance
qs ipc call powerProfile set power-saver
```

Requires `power-profiles-daemon` to be enabled.

## Wallpaper management

- `Ctrl + Super + T` — open wallpaper selector
- `Ctrl + Super + Alt + T` — random wallpaper

The Wallpaper Slideshow module can auto-rotate wallpapers on a timer. Configure it in Settings → Wallpaper Slideshow.

## AI integration

### Ollama
The fork auto-starts `ollama serve` on login. The AI chat sidebar (`Super + A`) connects to your local Ollama instance.

### Quick launch
`Super + Space` launches Ollama Claude with the minimax model.

## Clipboard & emoji

- `Super + V` opens clipboard history (powered by `cliphist`)
- `Super + .` opens the emoji picker with fuzzy search
- Both work with Quickshell's native UI when available, falling back to `fuzzel` otherwise
