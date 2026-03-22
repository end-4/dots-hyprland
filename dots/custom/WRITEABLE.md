# Writeable Files Guide

This document provides a complete reference of all files and locations you can safely edit to make these dotfiles your own. Files here are **preserved across updates** and **won't conflict** with upstream changes.

---

## Complete File Structure

### dots/custom/ - Personal Extensions (This Directory)
```
dots/custom/
├── [README.md](./README.md)                    ← Detailed documentation
├── [WRITEABLE.md](./WRITEABLE.md)              ← This file
├── [packages.sh](./packages.sh)                ← Extra packages installer
├── [files.sh](./files.sh)                      ← Extra files copier
├── [commands.sh](./commands.sh)                ← Extra commands runner
├── [misc.sh](./misc.sh)                        ← Miscellaneous operations
├── [updater.sh](./updater.sh)                  ← Force-update script
└── files/                                      ← Storage for custom files (optional)
    ├── .config/
    │   └── myapp/
    │       └── config.conf
    └── .local/
        └── bin/
            └── my-script.sh
```

### dots/.config/hypr/ - Hyprland Configuration
```
dots/.config/hypr/
├── [hyprland.conf](../.config/hypr/hyprland.conf)                    ← Main entry point
├── [hypridle.conf](../.config/hypr/hypridle.conf)                    ← Idle management
├── [hyprlock.conf](../.config/hypr/hyprlock.conf)                    ← Lock screen
├── [monitors.conf](../.config/hypr/monitors.conf)                    ← Monitor config
├── [workspaces.conf](../.config/hypr/workspaces.conf)                ← Workspace rules
│
├── custom/                                                           ← USER CUSTOMIZATIONS
│   ├── [env.conf](../.config/hypr/custom/env.conf)                   ← Environment variables
│   ├── [execs.conf](../.config/hypr/custom/execs.conf)               ← Autostart apps
│   ├── [general.conf](../.config/hypr/custom/general.conf)           ← General settings
│   ├── [keybinds.conf](../.config/hypr/custom/keybinds.conf)       ← Keybindings
│   ├── [rules.conf](../.config/hypr/custom/rules.conf)               ← Window rules
│   └── scripts/
│       └── [__restore_video_wallpaper.sh](../.config/hypr/custom/scripts/__restore_video_wallpaper.sh)
│
└── hyprland/             ← Core configs (edit custom/ instead)
    ├── colors.conf
    ├── env.conf
    ├── execs.conf
    ├── general.conf
    ├── keybinds.conf
    ├── rules.conf
    └── scripts/
```

---

## Section 1: dots/custom/ - Personal Extensions

**Location:** `dots/custom/` in your repo clone

This is your personal space for additions that integrate with the install script. These files are **sourced at the end** of `./setup install` and are **never overwritten** by upstream updates.

### [README.md](./README.md)
| Property | Value |
|----------|-------|
| **Type** | Documentation |
| **Purpose** | Main documentation for the custom additions system |
| **Contents** | Detailed guides for each script with usage examples, troubleshooting |
| **When to read** | First time setting up custom additions |
| **Safe to edit** | ✅ Yes - this is your local documentation |

### [WRITEABLE.md](./WRITEABLE.md)
| Property | Value |
|----------|-------|
| **Type** | Documentation |
| **Purpose** | Complete reference of all user-writeable locations |
| **Contents** | Every location you can customize across the entire repository |
| **When to read** | When looking for what files you can safely edit |
| **Safe to edit** | ✅ Yes - this is your personal reference |

### [packages.sh](./packages.sh)
| Property | Value |
|----------|-------|
| **Type** | Shell script (Bash) |
| **Purpose** | Define extra packages to install during setup |
| **Function** | `custom_packages()` |
| **Key Features** | One package per line (after `#` comment), cross-distro support |

**Usage Pattern:**
```bash
custom_packages() {
    # firefox
    # vlc
    # thunderbird
}
```

**Supported Distros:** Arch (pacman), Fedora (dnf), Debian/Ubuntu (apt), Gentoo (emerge)

### [files.sh](./files.sh)
| Property | Value |
|----------|-------|
| **Type** | Shell script (Bash) |
| **Purpose** | Copy additional config files to your system |
| **Function** | `custom_files()` |
| **Key Features** | Uses `rsync_dir` and `cp_file` helper functions |

**Available Helper Functions:**
| Function | Syntax | Purpose |
|----------|--------|---------|
| `cp_file` | `cp_file "source" "destination"` | Copy single file |
| `rsync_dir` | `rsync_dir "source_dir" "dest_dir"` | Copy directory recursively |

**Usage Example:**
```bash
custom_files() {
    local src_dir="dots/custom/files"
    local dest_dir="$HOME"
    rsync_dir "$src_dir" "$dest_dir"
}
```

### [commands.sh](./commands.sh)
| Property | Value |
|----------|-------|
| **Type** | Shell script (Bash) |
| **Purpose** | Run arbitrary shell commands during installation |
| **Function** | `custom_commands()` |
| **Key Features** | One command per line, supports pipes and redirects |

**Usage Pattern:**
```bash
custom_commands() {
    # mkdir -p ~/.local/share/myapp
    # systemctl --user enable myservice
    # chmod +x ~/.local/bin/myscript
}
```

### [misc.sh](./misc.sh)
| Property | Value |
|----------|-------|
| **Type** | Shell script (Bash) |
| **Purpose** | Miscellaneous customizations (symlinks, env vars) |
| **Function** | `custom_misc()` |

**Usage Pattern:**
```bash
custom_misc() {
    # ln -sf "$(pwd)/dots/custom/scripts/my-script.sh" "$HOME/.local/bin/my-script"
    # chmod +x "$HOME/.local/bin/my-script"
}
```

### [updater.sh](./updater.sh)
| Property | Value |
|----------|-------|
| **Type** | Shell script (Bash) |
| **Purpose** | Forcefully update configuration files from repo to live system |
| **Can run directly** | `bash dots/custom/updater.sh` |

**Command-Line Options:**

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-y, --yes` | Auto-confirm all prompts (dangerous) |
| `-n, --dry-run` | Show what would be done without doing it |
| `--skip-backup` | Skip backup of existing configs |
| `--only-quickshell` | Only update Quickshell configs |
| `--only-hyprland` | Only update Hyprland configs |
| `--no-reload` | Don't reload Hyprland/Quickshell after update |

**Usage Examples:**
```bash
bash dots/custom/updater.sh                    # Interactive mode
bash dots/custom/updater.sh -y                 # Auto-confirm with backup
bash dots/custom/updater.sh -y --skip-backup   # Auto-confirm, no backup
bash dots/custom/updater.sh --only-quickshell -y
bash dots/custom/updater.sh -n                 # Dry run
```

### [files/](./files/) (Optional Directory)
| Property | Value |
|----------|-------|
| **Type** | Directory |
| **Purpose** | Storage for files to be copied during install |
| **Structure** | Mirror your home directory structure |

**Example Structure:**
```
dots/custom/files/
├── .config/
│   └── myapp/
│       └── config.conf
├── .local/
│   └── bin/
│       └── my-script.sh
└── .themes/
    └── MyCustomTheme/
```

---

## Section 2: dots/.config/hypr/custom/ - Hyprland User Configuration

**Location:** `dots/.config/hypr/custom/` in your repo

These files are **intended for user customizations** and are sourced by the main Hyprland config. They are **preserved across updates**. The main config sources them at the end, so your settings override defaults.

### [../.config/hypr/custom/env.conf](../.config/hypr/custom/env.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Environment variables for Hyprland |
| **What to add** | PATH modifications, tool-specific env vars, input method settings |
| **Sourced by** | `hyprland.conf` → `hyprland/env.conf` (after custom/env.conf) |
| **Safe to edit** | ✅ Yes |

**Common Additions:**
```conf
# Input method (Fcitx5)
env = QT_IM_MODULE, fcitx
env = XMODIFIERS, @im=fcitx
env = SDL_IM_MODULE, fcitx

# Editor
env = EDITOR, nvim

# Tearing for gaming
env = WLR_DRM_NO_ATOMIC, 1
```

### [../.config/hypr/custom/execs.conf](../.config/hypr/custom/execs.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Autostart applications |
| **What to add** | `exec-once` commands for your apps |
| **Sourced by** | `hyprland.conf` → `hyprland/execs.conf` |
| **Safe to edit** | ✅ Yes |

**Common Additions:**
```conf
# Input method
exec-once = fcitx5

# Cloud sync
exec-once = nextcloud --background

# Notification daemon
exec-once = mako

# Clipboard manager
exec-once = wl-paste --type text --watch cliphist store
```

### [../.config/hypr/custom/general.conf](../.config/hypr/custom/general.conf)
| Property | Value |
|----------|-------|
| **Purpose** | General Hyprland settings |
| **What to add** | Window rules, input settings, decoration tweaks |
| **Sourced by** | `hyprland.conf` → `hyprland/general.conf` |
| **Safe to edit** | ✅ Yes |

**Common Additions:**
```conf
# Touchpad settings
input {
    touchpad {
        natural_scroll = true
        disable_while_typing = false
    }
}

# Monitor-specific reserved area
monitor=,addreserved, 0, 0, 0, 0

# HDMI mirroring (use `hyprctl monitors` for device names)
# monitor = HDMI-A-1, 1920x1080@60, auto, 1, mirror, eDP-1
```

### [../.config/hypr/custom/keybinds.conf](../.config/hypr/custom/keybinds.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Additional keybindings |
| **What to add** | Your custom keybindings |
| **Sourced by** | `hyprland.conf` → `hyprland/keybinds.conf` |
| **Safe to edit** | ✅ Yes |
| **CheatSheet** | Use `#!` for extra column, `##!` for section headers |

**Syntax:**
```conf
# Basic bind
bind = Super, F, exec, firefox

# Bind with shift
bind = Super Shift, S, exec, ~/.local/bin/my-script.sh

# Mouse bind
bindm = Super, mouse:272, movewindow

# For cheatsheet (adds description)
bind = Super, B, exec, brave  # [hidden] Browser
```

**Common Additions:**
```conf
#! User
##! Apps
bind = Super, F, exec, firefox
bind = Super, E, exec, dolphin
bind = Super Shift, Return, exec, alacritty

##! Media
bind = ,XF86AudioPlay, exec, playerctl play-pause
bind = ,XF86AudioNext, exec, playerctl next
```

### [../.config/hypr/custom/rules.conf](../.config/hypr/custom/rules.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Window rules |
| **What to add** | Rules for specific applications |
| **Sourced by** | `hyprland.conf` → `hyprland/rules.conf` |
| **Safe to edit** | ✅ Yes |

**Common Rules:**
```conf
# Float dialogs
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(imv)$
windowrule = float, ^(mpv)$

# Assign to workspaces
windowrule = workspace 1, ^(firefox)$
windowrule = workspace 2, ^(code)$
windowrule = workspace 3, ^(discord)$

# Opacity
windowrule = opacity 0.9, ^(kitty)$
windowrule = opacity 0.95, ^(alacritty)$

# No blur for xwayland
windowrule = no_blur on, match:xwayland 1

# Pin (always on top)
windowrule = pin, ^(scratchpad)$

# Size for floating windows
windowrule = size 800 600, ^(pavucontrol)$
```

### [../.config/hypr/custom/scripts/__restore_video_wallpaper.sh](../.config/hypr/custom/scripts/__restore_video_wallpaper.sh)
| Property | Value |
|----------|-------|
| **Type** | Shell script (Bash) |
| **Purpose** | Auto-generated script to restore video wallpaper on login |
| **Generated by** | `switchwall.sh` when setting video wallpaper |
| **Safe to edit** | ⚠️ No - will be overwritten by switchwall.sh |

---

## Section 3: Hyprland Monitor and Workspace Configuration

### [../.config/hypr/monitors.conf](../.config/hypr/monitors.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Monitor configuration (resolution, position, scale) |
| **Installed to** | `~/.config/hypr/monitors.conf` |
| **Managed by** | Can be overwritten by `nwg-displays` GUI tool |
| **Safe to edit** | ✅ Yes - this is your personal config |

**Syntax:**
```conf
# Basic monitor
monitor = DP-1, 2560x1440@144, 0x0, 1

# With scaling
monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1.25

# Mirror mode
monitor = HDMI-A-1, 1920x1080@60, auto, 1, mirror, DP-1

# Disable a monitor
monitor = HDMI-A-1, disable

# Auto-detect preferred mode
monitor = ,preferred, auto, 1
```

**Get monitor names:**
```bash
hyprctl monitors
```

### [../.config/hypr/workspaces.conf](../.config/hypr/workspaces.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Workspace rules and monitor assignments |
| **Installed to** | `~/.config/hypr/workspaces.conf` |
| **Managed by** | Can be overwritten by `nwg-displays` GUI tool |
| **Safe to edit** | ✅ Yes - this is your personal config |

**Syntax:**
```conf
# Assign workspaces to monitors
workspace = 1, monitor:DP-1
workspace = 2, monitor:DP-1
workspace = 9, monitor:HDMI-A-1
workspace = 10, monitor:HDMI-A-1

# Persistent workspaces
workspace = special:scratchpad, persistent:true

# Workspace rules
workspace = special:magic, on-created-empty:firefox
```

---

## Section 4: Hyprland Lock and Idle Configuration

### [../.config/hypr/hyprlock.conf](../.config/hypr/hyprlock.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Lock screen configuration |
| **Installed to** | `~/.config/hypr/hyprlock.conf` |
| **Safe to edit** | ✅ Yes (copy to custom folder to preserve) |

**Key Sections:**
- `background` - Wallpaper/path settings
- `input-field` - Password input appearance
- `label` - Time, date, and other labels
- `image` - Profile picture/user avatar

### [../.config/hypr/hypridle.conf](../.config/hypr/hypridle.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Idle management (screen dimming, locking, suspend) |
| **Installed to** | `~/.config/hypr/hypridle.conf` |
| **Safe to edit** | ✅ Yes |

**Example Structure:**
```conf
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
}

# Screen dim
listener {
    timeout = 300
    on-timeout = brightnessctl -s set 10
    on-resume = brightnessctl -r
}

# Lock screen
listener {
    timeout = 600
    on-timeout = loginctl lock-session
}

# Screen off
listener {
    timeout = 900
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
```

---

## Section 5: Application Configurations

### Kitty (Terminal Emulator)

#### [../.config/kitty/kitty.conf](../.config/kitty/kitty.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Terminal emulator configuration |
| **Installed to** | `~/.config/kitty/kitty.conf` |
| **Safe to edit** | ✅ Yes - copy to `dots/custom/files/.config/kitty/` |

**Common Settings:**
| Setting | Description |
|---------|-------------|
| `font_family` | Terminal font |
| `font_size` | Font size |
| `background_opacity` | Terminal transparency (0.0-1.0) |
| `cursor_shape` | Cursor style (block, beam, underline) |
| `shell` | Default shell |
| `enable_audio_bell` | Audio bell on/off |

**Example:**
```conf
font_family      JetBrainsMono Nerd Font
font_size        11.0
background_opacity 0.95
cursor_shape     beam
enable_audio_bell no
```

### MPV (Video Player)

#### [../.config/mpv/mpv.conf](../.config/mpv/mpv.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Video player settings |
| **Installed to** | `~/.config/mpv/mpv.conf` |
| **Safe to edit** | ✅ Yes |

**Common Settings:**
```conf
# Hardware acceleration
hwdec=auto-safe

# Keep aspect ratio when resizing
keepaspect-window=no

# Always show window title
force-window=immediate

# Default volume
volume=100
volume-max=100

# Screenshots
screenshot-directory=~/Pictures/mpv-screenshots
screenshot-template=%F-%P
```

### Fuzzel (Application Launcher)

#### [../.config/fuzzel/fuzzel.ini](../.config/fuzzel/fuzzel.ini)
| Property | Value |
|----------|-------|
| **Purpose** | Launcher appearance and behavior |
| **Installed to** | `~/.config/fuzzel/fuzzel.ini` |
| **Safe to edit** | ✅ Yes (colors auto-generated by matugen) |

**Key Sections:**
- `main` - General settings (font, icons, matching)
- `colors` - Color scheme (auto-generated)
- `border` - Border settings
- `key-bindings` - Keyboard shortcuts

#### [../.config/fuzzel/fuzzel_theme.ini](../.config/fuzzel/fuzzel_theme.ini)
| Property | Value |
|----------|-------|
| **Purpose** | Color theme for fuzzel |
| **Generated by** | matugen |
| **Safe to edit** | ⚠️ Will be overwritten by matugen |

### Wlogout (Logout Menu)

#### [../.config/wlogout/layout](../.config/wlogout/layout)
| Property | Value |
|----------|-------|
| **Purpose** | Button layout configuration |
| **Installed to** | `~/.config/wlogout/layout` |
| **Safe to edit** | ✅ Yes |

**Buttons:** lock, logout, suspend, hibernate, shutdown, reboot

#### [../.config/wlogout/style.css](../.config/wlogout/style.css)
| Property | Value |
|----------|-------|
| **Purpose** | CSS styling for wlogout |
| **Installed to** | `~/.config/wlogout/style.css` |
| **Safe to edit** | ✅ Yes |

### Starship (Shell Prompt)

#### [../.config/starship.toml](../.config/starship.toml)
| Property | Value |
|----------|-------|
| **Purpose** | Cross-shell prompt customization |
| **Installed to** | `~/.config/starship.toml` |
| **Safe to edit** | ✅ Yes |

**Key Features:**
- Git status integration
- Directory icons and substitutions
- Command duration
- Custom formatting

**Important Modules:**
| Module | Purpose |
|--------|---------|
| `[character]` | Prompt symbol (success/error) |
| `[directory]` | Current directory with icons |
| `[git_branch]` | Git branch display |
| `[git_status]` | Git status icons |
| `[cmd_duration]` | Last command duration |

---

## Section 6: Shell Configuration

### Fish

#### [../.config/fish/config.fish](../.config/fish/config.fish)
| Property | Value |
|----------|-------|
| **Purpose** | Fish shell configuration |
| **Installed to** | `~/.config/fish/config.fish` |
| **Safe to edit** | ✅ Yes |

**Common Additions:**
```fish
# Aliases
alias ll "ls -la"
alias g git
alias n nvim

# PATH modifications
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin

# Environment variables
set -x EDITOR nvim
set -x TERMINAL kitty

# Abbreviations (auto-expand)
abbr -a gs 'git status'
abbr -a ga 'git add'
abbr -a gc 'git commit'
```

#### [../.config/fish/auto-Hypr.fish](../.config/fish/auto-Hypr.fish)
| Property | Value |
|----------|-------|
| **Purpose** | Auto-start Hyprland on TTY1 login |
| **Installed to** | `~/.config/fish/auto-Hypr.fish` |
| **Safe to edit** | ✅ Yes |

### Zsh

#### [../.config/zshrc.d/](../.config/zshrc.d/)
| Property | Value |
|----------|-------|
| **Purpose** | Zsh configuration snippets |
| **Files** | `auto-Hypr.sh`, `dots-hyprland.zsh`, `shortcuts.zsh` |
| **Safe to edit** | ✅ Yes |

---

## Section 7: Theming and Appearance

### Matugen (Material Color Generation)

#### [../.config/matugen/config.toml](../.config/matugen/config.toml)
| Property | Value |
|----------|-------|
| **Purpose** | Template generation configuration |
| **Installed to** | `~/.config/matugen/config.toml` |
| **Safe to edit** | ✅ Yes |

**Key Configuration:**
```toml
[templates]
hyprland = { input = '...', output = '...' }
fuzzel = { input = '...', output = '...' }
```

#### [../.config/matugen/templates/](../.config/matugen/templates/)
| Property | Value |
|----------|-------|
| **Purpose** | Color scheme templates |
| **Templates** | hyprland/, fuzzel/, gtk-3.0/, gtk-4.0/, kde/, ags/ |
| **Safe to edit** | ✅ Yes |

**Available Templates:**

| Template | Output | Description |
|----------|--------|-------------|
| `hyprland/colors.conf` | Hyprland border colors | Window border theming |
| `hyprland/hyprlock-colors.conf` | Lock screen colors | Hyprlock color scheme |
| `fuzzel/fuzzel_theme.ini` | Launcher theme | Fuzzel color scheme |
| `gtk-3.0/` | GTK3 theme | Legacy GTK app theming |
| `gtk-4.0/` | GTK4 theme | Modern GTK app theming |
| `kde/` | KDE/Qt colors | KDE application theming |
| `colors.json` | JSON colors | General color reference |

**Template Variables:**

| Variable | Description |
|----------|-------------|
| `{{colors.primary.default}}` | Primary color |
| `{{colors.secondary.default}}` | Secondary color |
| `{{colors.tertiary.default}}` | Tertiary/accent color |
| `{{colors.surface.default}}` | Surface color |
| `{{colors.surface_variant.default}}` | Surface variant |
| `{{colors.background.default}}` | Background color |
| `{{colors.error.default}}` | Error color |
| `{{colors.outline.default}}` | Outline color |

### KDE Material You Colors

#### [../.config/kde-material-you-colors/config.conf](../.config/kde-material-you-colors/config.conf)
| Property | Value |
|----------|-------|
| **Purpose** | KDE/Qt theming with Material You colors |
| **Installed to** | `~/.config/kde-material-you-colors/config.conf` |
| **Safe to edit** | ✅ Yes |

**Key Options:**

| Option | Values | Description |
|--------|--------|-------------|
| `monitor` | 0, 1, 2... | Which monitor's wallpaper to use |
| `file` | path | Static wallpaper file path |
| `light` | True/False | Force light/dark mode |
| `scheme_variant` | 0-8 | Material You scheme variant |
| `iconslight` | theme name | Light icons theme |
| `iconsdark` | theme name | Dark icons theme |
| `pywal` | True/False | Enable pywal integration |
| `ncolor` | 0+ | Alternative color mode |
| `chroma_multiplier` | float | Colorfulness |
| `tone_multiplier` | float | Brightness (0.5-1.5) |

**Scheme Variants:**
| Value | Variant |
|-------|---------|
| 0 | Content |
| 1 | Expressive |
| 2 | Fidelity |
| 3 | Monochrome |
| 4 | Neutral |
| 5 | TonalSpot (default) |
| 6 | Vibrant |
| 7 | Rainbow |
| 8 | FruitSalad |

### Kvantum (Qt Theme Engine)

#### [../.config/Kvantum/kvantum.kvconfig](../.config/Kvantum/kvantum.kvconfig)
| Property | Value |
|----------|-------|
| **Purpose** | Kvantum theme selection |
| **Installed to** | `~/.config/Kvantum/kvantum.kvconfig` |
| **Safe to edit** | ✅ Yes |

#### [../.config/Kvantum/Colloid/](../.config/Kvantum/Colloid/)
| Property | Value |
|----------|-------|
| **Purpose** | Colloid theme for Qt apps |
| **Safe to edit** | ✅ Yes |

#### [../.config/Kvantum/MaterialAdw/](../.config/Kvantum/MaterialAdw/)
| Property | Value |
|----------|-------|
| **Purpose** | MaterialAdw theme for Qt apps |
| **Safe to edit** | ✅ Yes |

### Font Configuration

#### [../.config/fontconfig/fonts.conf](../.config/fontconfig/fonts.conf)
| Property | Value |
|----------|-------|
| **Purpose** | System font configuration |
| **Installed to** | `~/.config/fontconfig/fonts.conf` |
| **Safe to edit** | ✅ Yes |

---

## Section 8: Browser Flags

### [../.config/chrome-flags.conf](../.config/chrome-flags.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Chromium/Chrome launch flags |
| **Installed to** | `~/.config/chrome-flags.conf` |
| **Safe to edit** | ✅ Yes |

### [../.config/code-flags.conf](../.config/code-flags.conf)
| Property | Value |
|----------|-------|
| **Purpose** | VS Code launch flags |
| **Installed to** | `~/.config/code-flags.conf` |
| **Safe to edit** | ✅ Yes |

### [../.config/thorium-flags.conf](../.config/thorium-flags.conf)
| Property | Value |
|----------|-------|
| **Purpose** | Thorium browser launch flags |
| **Installed to** | `~/.config/thorium-flags.conf` |
| **Safe to edit** | ✅ Yes |

**Common Flags:**
```
--enable-features=UseOzonePlatform
--ozone-platform=wayland
--enable-features=WebRTCPipeWireCapturer
--force-dark-mode
```

---

## Section 9: Quickshell Configuration

**Location:** `dots/.config/quickshell/ii/`

### User-Editable Files

#### [../.config/quickshell/ii/defaults/ai/prompts/](../.config/quickshell/ii/defaults/ai/prompts/)
| Property | Value |
|----------|-------|
| **Purpose** | AI assistant personality prompts |
| **Safe to edit** | ✅ Yes - copy to custom folder |

**Available Prompts:**

| Prompt File | Personality |
|-------------|-------------|
| `ii-Default.md` | Helpful assistant with casual tone |
| `ii-Imouto.md` | Japanese little sister (imouto) personality |
| `nyarch-Acchan.md` | Nyarch Linux personality (Acchan) |
| `w-FourPointedSparkle.md` | Waffle panel family personality |
| `w-OpenMechanicalFlower.md` | Alternative Waffle personality |
| `NoPrompt.md` | Empty prompt (raw model behavior) |

**Custom Prompt Variables:**

| Variable | Description |
|----------|-------------|
| `{DISTRO}` | Current Linux distribution |
| `{DE}` | Desktop environment (illogical-impulse) |
| `{DATETIME}` | Current date and time |
| `{WINDOWCLASS}` | Currently focused window class |

#### [../.config/quickshell/ii/defaults/ai/README.md](../.config/quickshell/ii/defaults/ai/README.md)
| Property | Value |
|----------|-------|
| **Purpose** | Documentation for AI prompts |
| **Safe to edit** | ✅ Yes |

### Runtime Configuration

**Settings App:**
- **Launch:** `Super + I` or run `qs -c ii settings.qml`
- **File:** `~/.config/quickshell/ii/config.json`

**Safe to Edit via Settings:**
- Bar appearance (position, style, widgets)
- Colors and transparency
- Font settings
- Keyboard shortcuts (within Quickshell)
- AI model configuration
- Widget settings

---

## Section 10: Post-Install Live Configs

After installation, configs live in `~/.config/`. These can be edited directly:

### Safe to Edit Anytime (Live Configs)

| Location | What to Change |
|----------|----------------|
| `~/.config/hypr/custom/` | Hyprland customizations |
| `~/.config/quickshell/ii/config.json` | Quickshell settings |
| `~/.config/kitty/kitty.conf` | Terminal settings |
| `~/.config/mpv/mpv.conf` | Video player |
| `~/.config/fuzzel/fuzzel.ini` | Launcher |
| `~/.config/fish/config.fish` | Shell config |
| `~/.config/starship.toml` | Prompt |

### May Be Overwritten (Back Up First)

| Location | How to Customize Safely |
|----------|------------------------|
| `~/.config/hypr/hyprland.conf` | Edit `~/.config/hypr/custom/` instead |
| `~/.config/quickshell/ii/` QML files | Use settings app or defaults/ |
| `~/.config/matugen/templates/` | Copy to custom folder first |

---

## Section 11: Template Snippets

### Adding a Browser Keybinding

Edit `dots/custom/files/.config/hypr/custom/keybinds.conf`:
```conf
##! Apps
bind = Super, W, exec, firefox
```

Then in `dots/custom/files.sh`:
```bash
custom_files() {
    rsync_dir "dots/custom/files/.config/hypr/custom" "$HOME/.config/hypr/custom"
}
```

### Installing Extra Packages

Edit `dots/custom/packages.sh`:
```bash
custom_packages() {
    # firefox
    # thunderbird
    # keepassxc
    # obsidian
    # vscode
}
```

### Adding an Autostart App

Edit `dots/custom/files/.config/hypr/custom/execs.conf`:
```conf
exec-once = syncthing --no-browser
exec-once = nextcloud --background
exec-once = fcitx5
```

### Custom Script Installation

1. Create script: `dots/custom/files/.local/bin/my-script.sh`
2. Make executable in `dots/custom/commands.sh`:
```bash
custom_commands() {
    # chmod +x ~/.local/bin/my-script.sh
}
```

### Custom MPV Config

Create `dots/custom/files/.config/mpv/mpv.conf`:
```conf
hwdec=auto-safe
volume=100
volume-max=150
screenshot-directory=~/Pictures/mpv
```

### Custom Kitty Config

Create `dots/custom/files/.config/kitty/kitty.conf`:
```conf
font_family JetBrainsMono Nerd Font
font_size 12.0
background_opacity 0.95
cursor_shape beam
```

---

## Section 12: Complete Customization Checklist

Use this checklist when personalizing:

- [ ] Create `dots/custom/files/.config/hypr/custom/` structure
- [ ] Add custom keybindings in `keybinds.conf`
- [ ] Add autostart apps in `execs.conf`
- [ ] Add environment vars in `env.conf`
- [ ] Add window rules in `rules.conf`
- [ ] Configure monitors in `monitors.conf`
- [ ] Set up workspace rules in `workspaces.conf`
- [ ] Add packages to `packages.sh`
- [ ] Copy app configs to `dots/custom/files/.config/`
- [ ] Add personal scripts to `dots/custom/files/.local/bin/`
- [ ] Customize Fish shell in `fish/config.fish`
- [ ] Configure Starship prompt in `starship.toml`
- [ ] Set up Matugen templates
- [ ] Run `./setup install` to apply
- [ ] Customize via `Super + I` settings app

---

## Section 13: Update Behavior Reference

### Preserved Across Updates (Safe)

| Location | Mechanism |
|----------|-----------|
| `dots/custom/*` | Not tracked in upstream repo |
| `dots/.config/hypr/custom/*` | Preserved during install |
| `~/.config/hypr/custom/` | User customization directory |
| `~/.config/quickshell/ii/config.json` | User config, not in repo |
| `~/.config/hypr/monitors.conf` | Personal config |
| `~/.config/hypr/workspaces.conf` | Personal config |

### May Be Overwritten (Back Up First)

| Location | How to Customize Safely |
|----------|------------------------|
| `dots/.config/hypr/hyprland/*` | Use `dots/.config/hypr/custom/` |
| `dots/.config/quickshell/ii/modules/` | Use settings app or defaults/ |
| `dots/.config/matugen/templates/` | Copy to custom first |

---

## Section 14: File Reference by Application

| Application | Config Location | Live Location | Priority |
|-------------|-----------------|---------------|----------|
| **Hyprland Core** | `dots/.config/hypr/custom/` | `~/.config/hypr/custom/` | High |
| **Hyprland Monitors** | `dots/.config/hypr/monitors.conf` | `~/.config/hypr/monitors.conf` | High |
| **Hyprland Workspaces** | `dots/.config/hypr/workspaces.conf` | `~/.config/hypr/workspaces.conf` | Medium |
| **Hyprlock** | `dots/.config/hypr/hyprlock.conf` | `~/.config/hypr/hyprlock.conf` | Medium |
| **Hypridle** | `dots/.config/hypr/hypridle.conf` | `~/.config/hypr/hypridle.conf` | Medium |
| **Kitty** | `dots/.config/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` | Medium |
| **Fish** | `dots/.config/fish/config.fish` | `~/.config/fish/config.fish` | Medium |
| **MPV** | `dots/.config/mpv/mpv.conf` | `~/.config/mpv/mpv.conf` | Low |
| **Fuzzel** | `dots/.config/fuzzel/fuzzel.ini` | `~/.config/fuzzel/fuzzel.ini` | Low |
| **Wlogout** | `dots/.config/wlogout/` | `~/.config/wlogout/` | Low |
| **Starship** | `dots/.config/starship.toml` | `~/.config/starship.toml` | Medium |
| **Matugen** | `dots/.config/matugen/config.toml` | `~/.config/matugen/config.toml` | High |
| **KDE Material** | `dots/.config/kde-material-you-colors/config.conf` | `~/.config/kde-material-you-colors/config.conf` | Medium |
| **Kvantum** | `dots/.config/Kvantum/` | `~/.config/Kvantum/` | Low |
| **Quickshell** | `dots/.config/quickshell/ii/` | `~/.config/quickshell/ii/` | High |

---

*Last updated: 2026-03-22*
*This is a living document - expand as you customize!*
