# Writeable Files Guide

This document lists all files and locations you can safely edit to make these dotfiles your own. Files here are **preserved across updates** and **won't conflict** with upstream changes.

---

## Quick Reference

| Location | Purpose | Update-Safe |
|----------|---------|-------------|
| `dots/custom/` | Personal additions | Yes |
| `dots/.config/hypr/custom/` | Hyprland customizations | Yes |
| `dots/.config/hypr/monitors.conf` | Monitor configuration | Yes |
| `dots/.config/hypr/workspaces.conf` | Workspace rules | Yes |
| `dots/.config/fish/` | Shell configuration | Yes |
| `dots/.config/kitty/` | Terminal settings | Yes |
| `dots/.config/matugen/` | Color generation | Yes |
| `dots/.config/quickshell/ii/defaults/` | Default configurations | Partial |
| `~/.config/` (after install) | Live configs | Manual backup needed |

---

## 1. dots/custom/ - Personal Extensions

**Location:** `dots/custom/` in your repo clone

This is your personal space for additions that integrate with the install script.

### Available Files

#### packages.sh
- **Purpose:** Install extra packages via your package manager
- **Function:** `custom_packages()`
- **Example:** Add browsers, editors, media players
- **Docs:** See README.md in this folder

#### files.sh
- **Purpose:** Copy additional config files to your system
- **Function:** `custom_files()`
- **Example:** Custom app configs, personal scripts
- **Docs:** See README.md in this folder

#### commands.sh
- **Purpose:** Run custom commands during installation
- **Function:** `custom_commands()`
- **Example:** Enable services, set permissions, clone repos
- **Docs:** See README.md in this folder

#### misc.sh
- **Purpose:** Anything else (symlinks, environment variables)
- **Function:** `custom_misc()`
- **Example:** Create symlinks, set env vars
- **Docs:** See README.md in this folder

### How to Use

1. Edit the `.sh` files in this directory
2. Uncomment entries (remove leading `#`)
3. Run `./setup install` to apply

---

## 2. dots/.config/hypr/custom/ - Hyprland Configuration

**Location:** `dots/.config/hypr/custom/` in your repo

These files are **empty by default** and sourced by the main Hyprland config. Edit these to customize Hyprland without modifying core files.

### Available Files

#### env.conf
- **Purpose:** Environment variables for Hyprland
- **What to add:** PATH modifications, tool-specific env vars
- **Sourced by:** `hyprland.conf` → `hyprland/env.conf`

#### execs.conf
- **Purpose:** Autostart applications
- **What to add:** `exec-once` commands for your apps
- **Examples:** Start clipboard manager, notification daemon, cloud sync
- **Sourced by:** `hyprland.conf` → `hyprland/execs.conf`

#### general.conf
- **Purpose:** General Hyprland settings
- **What to add:** Window rules, input settings, decoration tweaks
- **Examples:** Touchpad settings, monitor scaling, gaps
- **Sourced by:** `hyprland.conf` → `hyprland/general.conf`

#### keybinds.conf
- **Purpose:** Additional keybindings
- **What to add:** Your custom keybindings
- **Examples:** App launchers, window management, scripts
- **Sourced by:** `hyprland.conf` → `hyprland/keybinds.conf`

#### rules.conf
- **Purpose:** Window rules
- **What to add:** Rules for specific applications
- **Examples:** Float dialogs, assign apps to workspaces, opacity rules
- **Sourced by:** `hyprland.conf` → `hyprland/rules.conf`

### How Updates Work

Files in `dots/.config/hypr/custom/` are copied to `~/.config/hypr/custom/` during install and preserved across updates. The main config sources them at the end, so your settings override defaults.

---

## 3. Quickshell Configuration

**Location:** `dots/.config/quickshell/ii/` in your repo

### User-Editable Files

#### defaults/
Contains default configurations that can be customized:

| File | Purpose | Edit? |
|------|---------|-------|
| `defaults/ai/prompts/` | AI personality prompts | Yes |
| `defaults/` | Default values | With caution |

#### Customization via Settings App

Most Quickshell settings are editable at runtime:
- **Settings app:** Press `Super + I` or run `qs -c ii settings.qml`
- **Config file:** `~/.config/quickshell/ii/config.json`

**Safe to edit via settings:**
- Bar appearance (position, style, widgets)
- Colors and transparency
- Font settings
- Keyboard shortcuts (within Quickshell)
- AI model configuration
- Widget settings

---

## 4. Application Configs

The following app configs in `dots/.config/` can be customized:

### Fully Safe (in dots/custom/)
Copy these to `dots/custom/files/.config/<app>/`:

- `kitty/` - Terminal emulator
- `mpv/` - Video player
- `matugen/` - Color generation templates
- `fuzzel/` - Application launcher
- `wlogout/` - Logout menu
- `hyprlock.conf` - Lock screen
- `hypridle.conf` - Idle management

### Direct Edit (backup recommended)
If editing directly in `dots/.config/`:

- `quickshell/ii/modules/common/Config.qml` - Main config structure
- `quickshell/ii/modules/common/Appearance.qml` - Theme/colors

---

## 5. Hyprland Monitor and Workspace Configuration

### monitors.conf
**Location:** `dots/.config/hypr/monitors.conf` → `~/.config/hypr/monitors.conf`

- **Purpose:** Monitor configuration (resolution, position, scale)
- **Managed by:** Can be overwritten by `nwg-displays` GUI tool
- **Safe to edit:** Yes, this is your personal config

### workspaces.conf
**Location:** `dots/.config/hypr/workspaces.conf` → `~/.config/hypr/workspaces.conf`

- **Purpose:** Workspace rules and monitor assignments
- **Managed by:** Can be overwritten by `nwg-displays` GUI tool
- **Safe to edit:** Yes, this is your personal config

**Example:**
```conf
# Assign workspaces to monitors
workspace = 1, monitor:DP-1
workspace = 2, monitor:DP-1
workspace = 9, monitor:HDMI-A-1
workspace = 10, monitor:HDMI-A-1
```

---

## 5. Post-Install Live Configs

After installation, configs live in `~/.config/`. These can be edited directly:

### Safe to Edit Anytime

| Location | What to Change |
|----------|----------------|
| `~/.config/hypr/custom/` | Hyprland customizations |
| `~/.config/quickshell/ii/config.json` | Quickshell settings |
| `~/.config/kitty/kitty.conf` | Terminal settings |
| `~/.config/mpv/mpv.conf` | Video player |
| `~/.config/fuzzel/fuzzel.ini` | Launcher |

### Back Up Before Editing

These may be overwritten by `exp-update`:

- `~/.config/hypr/hyprland.conf` (edit custom/ instead)
- `~/.config/quickshell/ii/` QML files (use defaults/ or settings)

---

## 6. Fish Shell Configuration

**Location:** `dots/.config/fish/` → `~/.config/fish/`

### config.fish
- **Purpose:** Fish shell configuration
- **Safe to edit:** Yes, but back up before major updates
- **Examples:** Add aliases, environment variables, abbreviations

### auto-Hypr.fish
- **Purpose:** Auto-start Hyprland on login (TTY1)
- **Safe to edit:** Yes, if you want different auto-start behavior

**Example for config.fish:**
```fish
# Add personal aliases
alias ll "ls -la"
alias g git

# Add to PATH
fish_add_path ~/.local/bin
```

---

### Custom Scripts Location

Place personal scripts in `dots/custom/files/.local/bin/` and add to `files.sh`:

```bash
custom_files() {
    local src="dots/custom/files"
    local dest="$HOME"
    rsync_dir "$src" "$dest"
}
```

### Script Templates

The main dotfiles have scripts in `dots/.config/quickshell/ii/scripts/`.
**Do not edit these directly** - copy and customize in your custom folder.

---

## 7. Application Configurations

### Kitty (Terminal Emulator)
**Location:** `dots/.config/kitty/kitty.conf`

| Setting | Description |
|---------|-------------|
| `font_family` | Terminal font |
| `font_size` | Font size |
| `background_opacity` | Terminal transparency |
| `cursor_shape` | Cursor style (block, beam, underline) |
| `shell` | Default shell |

**Safe to edit:** Yes - copy to `dots/custom/files/.config/kitty/`

### MPV (Video Player)
**Location:** `dots/.config/mpv/mpv.conf`

- **Purpose:** Video player settings
- **Safe to edit:** Yes - copy to `dots/custom/files/.config/mpv/`

### Fuzzel (Application Launcher)
**Location:** `dots/.config/fuzzel/fuzzel.ini`

- **Purpose:** Launcher appearance and behavior
- **Safe to edit:** Yes - colors auto-generated by matugen

### Kvantum (Qt Theme)
**Location:** `dots/.config/Kvantum/`

- **Purpose:** Qt application theming
- **Safe to edit:** Yes - themes for Colloid and MaterialAdw

---

## 8. Theming and Appearance

### Color Schemes

Colors are generated from wallpaper using `matugen`. To customize:

### config.toml
**Location:** `dots/.config/matugen/config.toml`

- **Purpose:** Template generation configuration
- **Safe to edit:** Yes

**Available Templates:**
| Template | Output |
|----------|--------|
| `m3colors` | Quickshell color scheme |
| `hyprland` | Hyprland border colors |
| `hyprlock` | Lock screen colors |
| `fuzzel` | Launcher theme |
| `gtk3` / `gtk4` | GTK application theming |
| `kde_colors` | KDE/Qt color scheme |
| `wallpaper` | Wallpaper path reference |

### Custom Templates
Create new templates in:
- `dots/custom/files/.config/matugen/templates/`

**Template syntax:** Uses Material Design 3 color tokens like `{{colors.primary.default}}`

### Available Color Tokens
- `{{colors.primary.default}}` - Primary color
- `{{colors.secondary.default}}` - Secondary color
- `{{colors.tertiary.default}}` - Tertiary/accent color
- `{{colors.surface.default}}` - Surface color
- `{{colors.background.default}}` - Background color
- `{{colors.error.default}}` - Error color

See existing templates in `dots/.config/matugen/templates/` for examples.

### Fonts

Set fonts via Quickshell settings or edit:
- `dots/.config/quickshell/ii/modules/common/Appearance.qml`

Better approach: Set in `dots/custom/misc.sh`:
```bash
custom_misc() {
    # echo 'export QT_QPA_PLATFORMTHEME=gtk2' >> "$HOME/.config/hypr/custom/env.conf"
}
```

---

## 8. Update Behavior

### Preserved Across Updates (Safe)

| Location | Mechanism |
|----------|-----------|
| `dots/custom/*` | Not in upstream repo |
| `~/.config/hypr/custom/` | Copied from dots/custom/ or kept |
| `~/.config/quickshell/ii/config.json` | User config, not in repo |

### May Be Overwritten (Back Up First)

| Location | How to Customize Safely |
|----------|------------------------|
| `dots/.config/hypr/hyprland/*` | Use `dots/.config/hypr/custom/` |
| `dots/.config/quickshell/ii/modules/` | Use settings app or defaults/ |

---

## 9. Template Snippets

### Adding a New Keybinding

Edit `dots/custom/files/.config/hypr/custom/keybinds.conf`:

```conf
# Example: Launch Firefox
bind = Super, F, exec, firefox

# Example: Custom script
bind = Super Shift, S, exec, ~/.local/bin/my-script.sh
```

Then in `dots/custom/files.sh`:
```bash
custom_files() {
    rsync_dir "dots/custom/files/.config/hypr/custom" "$HOME/.config/hypr/custom"
}
```

### Adding an Autostart App

Edit `dots/custom/files/.config/hypr/custom/execs.conf`:

```conf
# Example: Start syncthing
exec-once = syncthing --no-browser

# Example: Start custom service
exec-once = ~/.local/bin/my-service.sh
```

### Installing Extra Packages

Edit `dots/custom/packages.sh`:

```bash
custom_packages() {
    # firefox
    # thunderbird
    # keepassxc
    # obsidian
}
```

---

## 10. Quickshell Deep Customization

### defaults/ai/prompts/
**Location:** `dots/.config/quickshell/ii/defaults/ai/prompts/`

- **Purpose:** AI assistant personality prompts
- **Safe to edit:** Yes - copy to custom folder

**Available Prompts:**
| Prompt | Personality |
|--------|-------------|
| `ii-Default.md` | Helpful assistant with casual tone |
| `ii-Imouto.md` | Japanese little sister (imouto) personality |
| `nyarch-Acchan.md` | Nyarch Linux personality |
| `w-FourPointedSparkle.md` | Waffle panel family personality |
| `w-OpenMechanicalFlower.md` | Alternative Waffle personality |
| `NoPrompt.md` | Empty prompt (raw model behavior) |

**Custom Prompt Variables:**
- `{DISTRO}` - Current Linux distribution
- `{DE}` - Desktop environment
- `{DATETIME}` - Current date and time
- `{WINDOWCLASS}` - Currently focused window class

### GlobalStates.qml
**Location:** `~/.config/quickshell/ii/GlobalStates.qml` (generated)

- **Purpose:** Global state management
- **Safe to edit:** With caution - affects shell behavior

---

## 11. Checklist: Making It Yours

Use this checklist when personalizing:

- [ ] Create `dots/custom/files/.config/hypr/custom/` structure
- [ ] Add custom keybindings in `keybinds.conf`
- [ ] Add autostart apps in `execs.conf`
- [ ] Add environment vars in `env.conf`
- [ ] Add window rules in `rules.conf`
- [ ] Add packages to `packages.sh`
- [ ] Copy app configs to `dots/custom/files/.config/`
- [ ] Add personal scripts to `dots/custom/files/.local/bin/`
- [ ] Run `./setup install` to apply
- [ ] Customize via `Super + I` settings app

---

## TODO: Expand This Document

The following sections need to be filled in:

- [ ] Detailed explanation of each Hyprland custom file with examples
- [ ] Common customization recipes (keybindings, window rules, etc.)
- [ ] Quickshell widget customization examples
- [ ] Troubleshooting custom configurations
- [ ] Advanced: Creating new Quickshell widgets
- [ ] Advanced: Adding new quick toggles
- [ ] Advanced: Custom color scheme templates
- [ ] Distro-specific customizations
- [ ] Per-device configuration strategies

---

## Complete Customization Index

### By Category

| Category | Location | Priority |
|----------|----------|----------|
| **Core Hyprland** | `dots/.config/hypr/custom/` | High |
| **Shell Config** | `dots/.config/fish/` | Medium |
| **Terminal** | `dots/.config/kitty/` | Medium |
| **Launcher** | `dots/.config/fuzzel/` | Low |
| **Media** | `dots/.config/mpv/` | Low |
| **Colors** | `dots/.config/matugen/` | High |
| **Quickshell** | `dots/.config/quickshell/ii/` | High |
| **Custom Scripts** | `dots/custom/` | High |
| **Monitors** | `dots/.config/hypr/monitors.conf` | High |
| **Workspaces** | `dots/.config/hypr/workspaces.conf` | Medium |

---

*Last updated: 2026-03-21*
*This is a living document - expand as you customize!*
