---
title: Overview
description: What this fork adds to end-4/dots-hyprland and how the documentation is organized
---

## What is dots-hyprland?

[dots-hyprland](https://github.com/end-4/dots-hyprland) (a.k.a. **illogical-impulse**) is a usability-first Hyprland desktop environment built on:

- **Hyprland** — a dynamic tiling Wayland compositor
- **Quickshell** — a Qt6/QML-based shell framework for panels, sidebars, overlays, and widgets
- **Matugen** — Material Design 3 color generation from wallpapers
- **Various utilities** — hyprlock, hypridle, fuzzel, wf-recorder, grim, and more

The upstream project provides a complete desktop experience with window overview, clipboard history, emoji picker, media controls, screen recording, AI chat sidebar, and two panel families (_ii_ and _waffle_).

## What this fork adds

This repository ([omsenjalia/dots-hyprland](https://github.com/omsenjalia/dots-hyprland)) is a personal fork that adds:

### Power Profile Service
Cycle between Power Saver → Balanced → Performance with **Fn+Q** (or via IPC). Shows desktop notifications on each switch. Includes a full profile selector in System Settings.

### System Settings App
A comprehensive KDE/GNOME-style settings application (`SystemSettings.qml`) with a 3-column layout. Integrates both system-level controls (Display, Audio, Network, Bluetooth, Keyboard, Mouse, Power, Date & Time, Users) and existing dotfiles shell configuration in one unified app.

### Feature Modules
- **Wallpaper Slideshow** — auto-rotate wallpapers from a folder on a timer
- **YouTube Downloader** — download videos/audio via yt-dlp with a queue and progress UI
- **Emoji Picker Panel** — fuzzy-search emoji grid, copy on click

### Custom Keybinds
- `Super+Space` → launch Ollama Claude
- `Super+W` → cycle panel family
- `Super+B` → browser launcher
- `Ctrl+Super+S` → toggle special workspace
- `XF86Launch4` (Fn+Q) → cycle power profile

### Ollama Integration
The fork auto-starts `ollama serve` on login and includes keybinds for quick AI model access.

## Documentation structure

| Section | Purpose |
|---------|---------|
| **Guide** | Installation, usage, configuration, and troubleshooting |
| **Custom Additions** | Auto-generated docs from `dots/custom/` markdown files |
| **AI Agent Guide** | Architecture reference and workflow guide for AI coding assistants |

## Upstream documentation

For features from the original project, refer to the [upstream docs at ii.clsty.link](https://ii.clsty.link). This site focuses on fork-specific additions and agent-friendly architecture documentation.
