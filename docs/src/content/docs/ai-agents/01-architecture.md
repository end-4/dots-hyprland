---
title: Architecture
description: Component relationships, data flow, and key file locations for AI agents
---

## Component overview

The dotfiles consist of three major subsystems:

```
┌──────────────────────────────────────────┐
│              Hyprland (Compositor)        │
│  ┌─────────────┐  ┌──────────────────┐   │
│  │ hyprland.lua │  │ custom/*.lua     │   │
│  │ (upstream)   │  │ (user overrides) │   │
│  └──────┬──────┘  └────────┬─────────┘   │
│         └──────────┬───────┘             │
│                    ▼                     │
│         Hyprland runtime config          │
└──────────────────┬───────────────────────┘
                   │ IPC / globals
                   ▼
┌──────────────────────────────────────────┐
│         Quickshell (Shell / UI)           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │ shell.qml│ │ Services │ │ Modules  │  │
│  │ (entry)  │ │ (singletons)│ (UI)   │  │
│  └────┬─────┘ └────┬─────┘ └────┬────┘  │
│       └─────────────┼────────────┘       │
│                     ▼                    │
│           config.json (runtime)          │
└──────────────────┬───────────────────────┘
                   │ color generation
                   ▼
┌──────────────────────────────────────────┐
│         Matugen (Color Theming)           │
│  wallpaper → Material Design 3 colors    │
│  → CSS/QML/GTK templates                 │
└──────────────────────────────────────────┘
```

## Hyprland config system

### Entry point

`dots/.config/hypr/hyprland.lua` is the main config entry point. It loads files in order:

1. `hyprland/variables.lua` — default variable definitions (terminal, browser, etc.)
2. `custom/variables.lua` — user variable overrides
3. `hyprland/env.lua` — environment variables
4. `custom/env.lua` — user env overrides
5. `hyprland/general.lua` — monitor, gesture, and general settings
6. `custom/general.lua` — user general overrides
7. `hyprland/colors.lua` — matugen-generated color scheme
8. `hyprland/rules.lua` — window and workspace rules
9. `custom/rules.lua` — user rule additions
10. `hyprland/keybinds.lua` — all default keybindings
11. `custom/keybinds.lua` — user keybind overrides/additions
12. `hyprland/execs.lua` — autostart applications
13. `custom/execs.lua` — user autostart additions

**Key insight:** Custom files load _after_ their upstream counterparts, so user settings take precedence.

### Lua API

All config uses the `hl.*` global API provided by Hyprland's native Lua support:

| Function | Purpose |
|----------|---------|
| `hl.bind(mods, key, dispatcher, opts)` | Keybinding |
| `hl.dsp.exec_cmd(cmd)` | Dispatcher: execute command |
| `hl.dsp.global(name)` | Dispatcher: Quickshell global shortcut |
| `hl.dsp.togglespecialworkspace(name)` | Dispatcher: toggle scratchpad |
| `hl.exec_cmd(cmd)` | Execute command (on reload) |
| `hl.on("hyprland.start", fn)` | Execute on first start only |
| `hl.env(key, value)` | Set environment variable |
| `hl.config(table)` | Set config sections |
| `hl.monitor(table)` | Monitor configuration |
| `hl.window_rule(table)` | Window rules |

## Quickshell architecture

### Entry point

`dots/.config/quickshell/ii/shell.qml` is the Quickshell entry point. It loads:

- **Panel families** — `panelFamilies/IllogicalImpulseFamily.qml` (default) and `WaffleFamily.qml`
- **Services** — singletons in `services/` for system integration
- **Config** — `modules/common/Config.qml` manages `config.json`

### Key services

| Service | File | Purpose |
|---------|------|---------|
| Config | `modules/common/Config.qml` | JSON-based runtime config |
| Appearance | `modules/common/Appearance.qml` | Theme and colors |
| HyprlandConfig | `services/HyprlandConfig.qml` | Hyprland IPC integration |
| LauncherSearch | `services/LauncherSearch.qml` | App launcher backend |
| Wallpapers | `services/Wallpapers.qml` | Wallpaper management |
| Network | `services/Network.qml` | WiFi/network status |
| PowerProfileService | `services/PowerProfileService.qml` | Power profile cycling (fork addition) |

### Panel family system

Panel families are defined in `panelFamilies/`:
- Each family is a QML component that defines the complete UI layout
- `shell.qml` has a `families` list — add new families there
- Cycle with `panelFamilyCycle` global shortcut

### Config persistence

`Config.qml` → `JsonAdapter` → `config.json`

**Important:** Deeply nested property changes in QML don't trigger the JsonAdapter write signal. The fork added an explicit `save()` method that must be called after modifying config properties.

## Install system

`./setup install` orchestrates the installation:

1. Detects distro (Arch, Fedora, Gentoo, etc.)
2. Installs packages from `sdata/` package lists
3. Copies `dots/` to `~/.config/`
4. Sources `dots/custom/*.sh` and runs custom functions:
   - `custom_packages()` — installs extra packages
   - `custom_files()` — copies extra files
   - `custom_commands()` — runs arbitrary commands
   - `custom_misc()` — miscellaneous setup

## Color pipeline

```
Wallpaper image
    ↓ matugen
Material Design 3 palette (5 elevation layers)
    ↓ templates
├── GTK CSS (gtk.css)
├── Quickshell QML (colors via Appearance.qml)
├── Hyprland borders (colors.lua)
└── Various app configs (kitty, fuzzel, etc.)
```

Transparency is auto-calculated from wallpaper vibrancy.
