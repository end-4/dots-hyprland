# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**dots-hyprland** (branded "illogical-impulse" / "ii") is a comprehensive Hyprland desktop environment configuration. The UI shell is built with **Quickshell** (Qt6/QML widget framework), with supporting scripts in Bash and Python. It supports Arch, Fedora, Gentoo, and NixOS.

## Key Commands

### Installation
```bash
./setup install          # Full install (deps + setup + files)
./setup install-deps     # Install dependencies only
./setup install-setups   # Permission/service setup only
./setup install-files    # Copy config files only
./setup uninstall        # Remove
./setup exp-update       # Update without full reinstall
```

### Development (Quickshell UI)
```bash
pkill qs; qs -c ii       # Restart shell in terminal (shows logs, live-reloads on edit)
```
Edit files under `~/.config/quickshell/ii/` — changes reload live.

### QML LSP Setup
```bash
touch ~/.config/quickshell/ii/.qmlls.ini
```
VSCode: install "Qt Qml" extension, set custom exe path to `/usr/bin/qmlls6`.

### Python Virtual Environment
Python packages are managed via **uv** in a venv at `$ILLOGICAL_IMPULSE_VIRTUAL_ENV` (default: `~/.local/state/quickshell/.venv`).
```bash
# Add/remove dependencies
cd sdata/uv
# Edit requirements.in, then:
uv pip compile requirements.in -o requirements.txt
```
Python scripts use a special shebang to auto-activate the venv. For complex args, use a bash wrapper script instead (see `sdata/uv/README.md`).

### Translations
```bash
cd dots/.config/quickshell/ii/translations/tools
./manage-translations.sh status    # Check translation status
./manage-translations.sh extract   # Extract translatable texts
./manage-translations.sh update    # Update all translation files
./manage-translations.sh clean     # Remove unused keys
./manage-translations.sh sync      # Synchronize keys across languages
```
Translatable text must use `Translation.tr("text")` format in QML.

### Diagnostics
```bash
./diagnose               # Collect system info, optionally upload to pastebin
```

## Architecture

### Quickshell UI (`dots/.config/quickshell/ii/`)
The largest component (~56K lines QML). Entry point: `shell.qml` (ShellRoot).

- **`shell.qml`** — Root: loads panel families, initializes theme/services
- **`GlobalStates.qml`** — Shared state across the shell
- **`settings.qml`** — Settings interface
- **`modules/common/`** — Reusable components: `functions/` (DateUtils, ColorUtils, Fuzzy, etc.), `models/`, `widgets/`
- **`modules/ii/`** and **`modules/waffle/`** — Two switchable panel family implementations
- **`panelFamilies/`** — Panel layout templates; switched via `Config.options.panelFamily`
- **`services/`** — AI backends (Gemini/Ollama), Google Cloud auth, network utils, Hyprland shader control
- **`scripts/`** — Python/bash scripts for color generation, image processing, Hyprland config modification, cava, thumbnails, keyboard monitoring
- **`translations/`** — i18n JSON files + management tool suite

Color pipeline: wallpaper image -> `scheme_for_image.py` (OpenCV) -> `generate_colors_material.py` (Material Design 3) -> `applycolor.sh` -> theme applied to Quickshell + GTK + KDE + Hyprland

### Hyprland Config (`dots/.config/hypr/`)
- `hyprland.conf` sources sub-files from `hyprland/` (defaults) and `custom/` (user overrides)
- `$qsConfig = ii` links to Quickshell config
- Sub-files: `env.conf`, `general.conf`, `keybinds.conf`, `execs.conf`, `rules.conf`, `colors.conf`
- User customizations go in `custom/` which override the corresponding `hyprland/` defaults

### Setup System (`sdata/`)
- **`lib/`** — Core functions: `functions.sh` (841 LOC, `v()` verbose exec, `x()` error handling), `environment-variables.sh`, `package-installers.sh`, `dist-determine.sh`
- **`subcmd-*/`** — Modular install stages (greeting, deps, setups, files)
- **`dist-arch/`**, **`dist-fedora/`**, **`dist-gentoo/`**, **`dist-nix/`** — Per-distro packaging (Arch has 14 PKGBUILD meta-packages)
- **`uv/`** — Python dependency management (requirements.in -> requirements.txt)
- Installation is idempotent; tracks state via `~/.config/illogical-impulse/`

## Code Style (from CONTRIBUTING.md)

- Use spaces, not tabs. Group properties/children with single blank lines.
- Spaces around operators: `if (condition) { ... }` not `if(condition){...}`
- Prefer early return over deep nesting
- Use `component` keyword to declare reusable components in the same QML file when extracting to a new file feels excessive
- Non-essential features should use `Loader` (or `FadeLoader` with `shown` prop for fade animations); declare positioning on the Loader, not the sourceComponent
- Keep things practical for daily use; fancy-but-impractical features must be configurable and disabled by default
- Make multiple PRs for multiple features; don't bundle unrelated changes
