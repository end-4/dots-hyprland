# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is **end_4's Hyprland dotfiles** - a comprehensive Linux desktop configuration featuring:
- **Hyprland** as the Wayland compositor
- **Quickshell** (QtQuick-based widget system) for the status bar, sidebars, and panels
- **Material Design 3** inspired UI with accessible auto-generated colors
- Installation via `./setup` script supporting Arch, Fedora, Gentoo, and Nix-based distributions

## Common Commands

```bash
# Full installation
./setup install

# Partial installations
./setup install-deps    # Install dependencies only
./setup install-setups  # Setup permissions/services only
./setup install-files   # Copy config files only

# Experimental updates
./setup exp-update      # Update without full reinstall
./setup exp-merge       # Merge upstream changes via git rebase

# Generate diagnostic report
./diagnose

# Development
./setup virtmon         # Create virtual monitors for testing
./setup checkdeps       # Check if packages exist in AUR/repos
```

## Architecture

### Directory Structure

```
dots-hyprland/
├── dots/                    # Configuration files (XDG config home)
│   └── .config/
│       ├── quickshell/ii/  # Main Quickshell config (QML)
│       └── hyprland/        # Hyprland config (.conf files)
├── sdata/                   # Install script data
│   ├── lib/                 # Shared shell functions
│   ├── subcmd-*/            # Subcommand implementations
│   ├── dist-arch/           # Arch Linux PKGBUILDs (illogical-impulse-* packages)
│   ├── dist-fedora/         # Fedora-specific data
│   ├── dist-gentoo/         # Gentoo-specific data
│   └── dist-nix/            # Nix/home-manager configurations
├── setup                    # Main installation script
└── diagnose                 # Diagnostic script
```

### Quickshell Configuration (`dots/.config/quickshell/ii/`)

- **Entry point**: `shell.qml` - Contains `ShellRoot` component, loads panel families
- **Panel families**: `ii` (default) and `waffle` - switchable via `panelFamilyCycle` shortcut
- **Modules**:
  - `modules/common/` - Shared widgets, utilities, and functions
  - `modules/ii/` - Default panel family implementation
  - `modules/waffle/` - Alternative panel family
  - `modules/settings/` - Settings app modules
- **Services**: `services/` - Background services (wallpaper, AI, updates, etc.)
- **Scripts**: `scripts/` - Shell scripts for color switching, etc.

### Quickshell Module Structure

Each module typically contains:
- `Config.qml` - Module configuration
- Various QML components for the module's functionality

### Installation Script Architecture

The `setup` script sources these libraries from `sdata/lib/`:
- `environment-variables.sh` - XDG paths and styling constants
- `functions.sh` - Core functions: `v()` (verbose exec), `x()` (exec with error handling), `pause()`, `install_cmds()`, etc.
- `package-installers.sh` - Package-specific installers (fonts, MicroTeX, Python venv)
- `dist-determine.sh` - Distro detection logic

Subcommands are in `sdata/subcmd-*/` directories.

### Dependencies

**Python packages** are managed via `uv` in a virtual environment at `$XDG_STATE_HOME/quickshell/.venv` with Python 3.12. Requirements are in `sdata/uv/requirements.txt`.

**Core packages** are defined as meta-packages in `sdata/dist-arch/` with `illogical-impulse-` prefix. These include: audio, backlight, basic, fonts-themes, hyprland, kde, portal, python, screencapture, toolkit, widgets.

**Quickshell** itself is built from a pinned commit (defined in `sdata/dist-arch/illogical-impulse-quickshell-git/PKGBUILD`).

### Git Submodules

- `dots/.config/quickshell/ii/modules/common/widgets/shapes` → `https://github.com/end-4/rounded-polygon-qmljs.git`

Run `git submodule update --init --recursive` after cloning.

## Key Files

| File | Purpose |
|------|---------|
| `setup` | Main entry point for installation |
| `sdata/deps-info.md` | Detailed dependency information |
| `sdata/dist-arch/install-deps.sh` | Arch dependency installation |
| `dots/.config/quickshell/ii/shell.qml` | Quickshell entry point |
| `dots/.config/quickshell/ii/GlobalStates.qml` | Global state management |
| `dots/.config/quickshell/ii/settings.qml` | Settings application |
