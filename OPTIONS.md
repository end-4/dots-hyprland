# Illogical Impulse Dotfiles - Flake Options Reference

This document provides a comprehensive reference for all configuration options available in the Illogical Impulse dotfiles flake.

## Table of Contents

- [Master Options](#master-options)
- [Component Modules](#component-modules)
- [Hyprland Configuration](#hyprland-configuration)
- [Fish Shell Configuration](#fish-shell-configuration)
- [Terminal Configuration](#terminal-configuration)
- [Theme Configuration](#theme-configuration)
- [Configuration Files](#configuration-files)

## Master Options

### `illogical-impulse.enable`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Master enable switch for the Illogical Impulse dotfiles configuration. When enabled, the configuration system becomes active.

## Component Modules

All component modules follow the pattern: `illogical-impulse.<component>.enable`

### Essential Components

#### `illogical-impulse.audio.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: cava, pavucontrol-qt, wireplumber, libdbusmenu-gtk3, playerctl
- **Description**: Audio-related packages and dependencies

#### `illogical-impulse.basic.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: axel, bc, coreutils, cliphist, cmake, curl, rsync, wget, ripgrep, jq, meson, xdg-user-dirs
- **Description**: Basic utility packages

#### `illogical-impulse.fonts-themes.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: adw-gtk3, breeze-gtk, eza, fish, fontconfig, kitty, starship, nerdfonts, twemoji-color-font
- **Description**: Fonts and theming packages
- **Sub-options**:
  - `gtkTheme` (string, default: "adw-gtk3-dark"): GTK theme name
  - `iconTheme` (string, default: "breeze-dark"): Icon theme name
  - `cursorTheme` (string, default: "Bibata-Modern-Classic"): Cursor theme name

#### `illogical-impulse.hyprland.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: hypridle, hyprcursor, hyprland, hyprland-qtutils, hyprlang, hyprlock, hyprpicker, hyprsunset, hyprutils, hyprwayland-scanner, xdg-desktop-portal-hyprland, wl-clipboard
- **Description**: Hyprland compositor and related tools
- **Sub-options**: See [Hyprland Configuration](#hyprland-configuration)

#### `illogical-impulse.portal.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: xdg-desktop-portal, xdg-desktop-portal-kde, xdg-desktop-portal-gtk, xdg-desktop-portal-hyprland
- **Description**: XDG Desktop Portal implementations

#### `illogical-impulse.screencapture.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: hyprshot, slurp, swappy, tesseract (+ eng language), wf-recorder
- **Description**: Screenshot and screen recording tools

#### `illogical-impulse.toolkit.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: kdialog, Qt6 packages (qt5compat, qtbase, qtdeclarative, qtimageformats, qtmultimedia, etc.), syntax-highlighting, upower, wtype, ydotool
- **Description**: GTK/Qt toolkit dependencies

#### `illogical-impulse.widgets.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: fuzzel, glib, hypridle, hyprutils, hyprlock, hyprpicker, networkmanagerapplet, translate-shell, wlogout
- **Description**: Widget system dependencies

### Optional Components

#### `illogical-impulse.backlight.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: geoclue2, brightnessctl, ddcutil
- **Description**: Backlight control utilities (useful for laptops and external monitors)

#### `illogical-impulse.bibata-cursor.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: bibata-cursors
- **Description**: Bibata Modern Classic cursor theme

#### `illogical-impulse.kde.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: bluedevil, gnome-keyring, networkmanager, plasma-nm, polkit-kde-agent, dolphin, systemsettings
- **Description**: KDE and Plasma-related packages

#### `illogical-impulse.microtex.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: tinyxml-2, gtkmm3, gtksourceviewmm4, cairomm, git, cmake
- **Description**: MicroTeX mathematics rendering dependencies

#### `illogical-impulse.oneui4-icons.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: (requires manual installation or overlay)
- **Description**: OneUI4 icon theme (optional)

#### `illogical-impulse.python.enable`
- **Type**: `bool`
- **Default**: `false`
- **Packages**: clang, uv, gtk4, libadwaita, libsoup_3, libportal-gtk4, gobject-introspection, sassc, python3Packages.opencv4
- **Description**: Python development dependencies

## Hyprland Configuration

### `illogical-impulse.hyprland.enable`
- **Type**: `bool`
- **Default**: `false`
- **Description**: Enable Hyprland window manager

### `illogical-impulse.hyprland.package`
- **Type**: `package`
- **Default**: `pkgs.hyprland`
- **Description**: The Hyprland package to use

### `illogical-impulse.hyprland.monitors`
- **Type**: `list of strings`
- **Default**: `[ ",preferred,auto,1" ]`
- **Description**: Monitor configuration strings
- **Format**: `"name,resolution@rate,position,scale"`
- **Examples**:
  ```nix
  monitors = [
    ",preferred,auto,1"                    # Auto-detect all monitors
    "DP-1,1920x1080@60,0x0,1"             # Primary monitor
    "HDMI-A-1,1920x1080@60,1920x0,1"      # Secondary monitor to the right
  ];
  ```

### `illogical-impulse.hyprland.workspaces`
- **Type**: `list of strings`
- **Default**: `[ ]`
- **Description**: Workspace configuration strings
- **Format**: `"id, monitor:name, default:bool"`
- **Examples**:
  ```nix
  workspaces = [
    "1, monitor:DP-1, default:true"
    "2, monitor:HDMI-A-1"
  ];
  ```

### `illogical-impulse.hyprland.extraConfig`
- **Type**: `lines (multiline string)`
- **Default**: `""`
- **Description**: Extra Hyprland configuration to append to `custom/env.conf`
- **Example**:
  ```nix
  extraConfig = ''
    # Custom environment variables
    env = MY_VAR,value
    
    # Custom settings
    misc {
        disable_hyprland_logo = true
    }
  '';
  ```

## Fish Shell Configuration

### `illogical-impulse.fish.enable`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Enable Fish shell configuration

### `illogical-impulse.fish.enableStarship`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Enable Starship prompt integration

### `illogical-impulse.fish.aliases`
- **Type**: `attribute set of strings`
- **Default**:
  ```nix
  {
    pamcan = "pacman";
    ls = "eza --icons";
    clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    q = "qs -c ii";
  }
  ```
- **Description**: Fish shell command aliases
- **Example**:
  ```nix
  fish.aliases = {
    ll = "ls -la";
    gs = "git status";
    vim = "nvim";
  };
  ```

### `illogical-impulse.fish.autostart.hyprland`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Automatically start Hyprland when logging into tty1

## Terminal Configuration

### `illogical-impulse.terminal.default`
- **Type**: `string`
- **Default**: `"kitty"`
- **Description**: Default terminal emulator to use

### `illogical-impulse.terminal.kitty.enable`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Enable Kitty terminal and deploy its configuration files

## Theme Configuration

Theme options are provided by the `fonts-themes` module:

### `illogical-impulse.fonts-themes.gtkTheme`
- **Type**: `string`
- **Default**: `"adw-gtk3-dark"`
- **Description**: GTK theme name to use

### `illogical-impulse.fonts-themes.iconTheme`
- **Type**: `string`
- **Default**: `"breeze-dark"`
- **Description**: Icon theme name to use

### `illogical-impulse.fonts-themes.cursorTheme`
- **Type**: `string`
- **Default**: `"Bibata-Modern-Classic"`
- **Description**: Cursor theme name to use

## Configuration Files

### `illogical-impulse.configFiles.enable`
- **Type**: `bool`
- **Default**: `true`
- **Description**: Deploy configuration files from the `.config` directory to `~/.config`

When enabled, this option deploys the following configurations:

- **Hyprland** (when `hyprland.enable = true`):
  - `hypr/hyprland.conf`
  - `hypr/hypridle.conf`
  - `hypr/hyprlock.conf`
  - `hypr/hyprland/*.conf` (colors, env, execs, general, keybinds, rules)
  - `hypr/monitors.conf` (generated from `hyprland.monitors`)
  - `hypr/workspaces.conf` (generated from `hyprland.workspaces`)
  - `hypr/custom/*.conf` (empty templates for user customization)

- **Fish** (when `fish.enable = true`):
  - `fish/config.fish` (generated with custom aliases)
  - `fish/auto-Hypr.fish` (if `fish.autostart.hyprland = true`)

- **Terminal** (when `terminal.kitty.enable = true`):
  - `kitty/kitty.conf`
  - `kitty/scroll_mark.py`
  - `kitty/search.py`

- **Starship** (when `fish.enableStarship = true`):
  - `starship.toml`

- **Widgets** (when `widgets.enable = true`):
  - `fuzzel/` directory
  - `wlogout/` directory

- **Fonts & Themes** (when `fonts-themes.enable = true`):
  - `fontconfig/` directory

- **Toolkit** (when `toolkit.enable = true`):
  - `qt5ct/` directory
  - `qt6ct/` directory
  - `Kvantum/` directory

- **KDE** (when `kde.enable = true`):
  - `kdeglobals`
  - `dolphinrc`
  - `konsolerc`

- **Portal** (when `portal.enable = true`):
  - `xdg-desktop-portal/` directory

- **General**:
  - `foot/` directory
  - `chrome-flags.conf`
  - `code-flags.conf`
  - `thorium-flags.conf`

## Integration with Home Manager

The flake automatically configures the following Home Manager programs when their respective options are enabled:

- `wayland.windowManager.hyprland` - When `hyprland.enable = true`
- `programs.fish` - When `fish.enable = true`
- `programs.starship` - When `fish.enableStarship = true`
- `programs.kitty` - When `terminal.kitty.enable = true`

These are configured with minimal settings to ensure they work properly with the deployed configuration files.

## Example Configurations

### Minimal Configuration

```nix
illogical-impulse = {
  enable = true;
  basic.enable = true;
  hyprland.enable = true;
};
```

### Full Desktop Configuration

```nix
illogical-impulse = {
  enable = true;
  
  # Essential components
  audio.enable = true;
  basic.enable = true;
  fonts-themes.enable = true;
  hyprland.enable = true;
  portal.enable = true;
  screencapture.enable = true;
  toolkit.enable = true;
  widgets.enable = true;
  
  # Optional for laptops
  backlight.enable = true;
  
  # Hyprland configuration
  hyprland = {
    monitors = [ ",preferred,auto,1" ];
  };
  
  # Fish shell
  fish = {
    enable = true;
    enableStarship = true;
    autostart.hyprland = true;
  };
};
```

### Multi-Monitor Setup

```nix
illogical-impulse = {
  enable = true;
  hyprland = {
    enable = true;
    monitors = [
      "DP-1,2560x1440@144,0x0,1"      # Main monitor, 144Hz, left
      "HDMI-A-1,1920x1080@60,2560x0,1" # Second monitor, 60Hz, right
    ];
    workspaces = [
      "1, monitor:DP-1, default:true"
      "2, monitor:DP-1"
      "3, monitor:HDMI-A-1, default:true"
    ];
  };
};
```
