# Illogical Impulse Dotfiles - Flake Usage Guide

This flake provides a comprehensive Home Manager configuration for the Illogical Impulse dotfiles, featuring a modular design with toggleable components.

## Quick Start

### Using the Flake in Your Configuration

Add this flake as an input to your own `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    illogical-impulse = {
      url = "github:Version33/dots-hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { nixpkgs, home-manager, illogical-impulse, ... }: {
    homeConfigurations."yourusername" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      
      modules = [
        illogical-impulse.homeManagerModules.default
        {
          home = {
            username = "yourusername";
            homeDirectory = "/home/yourusername";
            stateVersion = "24.05";
          };

          illogical-impulse = {
            enable = true;
            
            # Enable the components you want
            audio.enable = true;
            basic.enable = true;
            hyprland.enable = true;
            fonts-themes.enable = true;
            portal.enable = true;
            toolkit.enable = true;
            widgets.enable = true;
            screencapture.enable = true;
            
            # Optionally enable additional components
            backlight.enable = true;
            kde.enable = false;
            python.enable = false;
            
            # Configure Hyprland
            hyprland = {
              monitors = [
                ",preferred,auto,1"  # Auto-configure all monitors
                # "DP-1,1920x1080@60,0x0,1"  # Example: specific monitor config
              ];
              autostart = true;  # Auto-start Hyprland on tty1
            };
          };
        }
      ];
    };
  };
}
```

### Applying the Configuration

```bash
# Build and activate the configuration
home-manager switch --flake .#yourusername
```

## Configuration Options

### Master Switch

- `illogical-impulse.enable` - Master enable switch for all dotfiles

### Component Modules

All component modules follow the same pattern: `illogical-impulse.<component>.enable`

#### Essential Components

- **audio** - Audio-related packages (cava, pavucontrol-qt, wireplumber, playerctl)
- **basic** - Basic utilities (axel, bc, coreutils, cliphist, cmake, curl, rsync, wget, ripgrep, jq)
- **hyprland** - Hyprland compositor and tools (hypridle, hyprlock, hyprpicker, etc.)
- **fonts-themes** - Fonts and theming (GTK themes, fonts, starship, fish, kitty)
- **toolkit** - GTK/Qt dependencies (Qt6 packages, KDE libraries, ydotool)
- **widgets** - Widget system dependencies (fuzzel, wlogout, networkmanager)
- **portal** - XDG Desktop Portals (hyprland, kde, gtk)
- **screencapture** - Screenshot and recording tools (hyprshot, slurp, swappy, wf-recorder)

#### Optional Components

- **backlight** - Backlight control (brightnessctl, ddcutil, geoclue2)
- **kde** - KDE-related packages (dolphin, plasma, qt apps)
- **python** - Python development dependencies
- **bibata-cursor** - Bibata Modern Classic cursor theme
- **microtex** - MicroTeX mathematics rendering
- **oneui4-icons** - OneUI4 icon theme

### Hyprland Configuration

```nix
illogical-impulse.hyprland = {
  enable = true;
  
  # Monitor configuration
  # Format: "name,resolution@rate,position,scale"
  monitors = [
    ",preferred,auto,1"                    # Auto-detect all monitors
    # "DP-1,1920x1080@60,0x0,1"           # Primary monitor
    # "HDMI-A-1,1920x1080@60,1920x0,1"    # Secondary monitor
  ];
  
  # Workspace configuration
  # Format: "id, monitor:name, default:bool"
  workspaces = [
    # "1, monitor:DP-1, default:true"
    # "2, monitor:HDMI-A-1"
  ];
  
  # Auto-start Hyprland on tty1
  autostart = true;
  
  # Extra configuration to append
  extraConfig = '''
    # Your custom Hyprland config here
  ''';
};
```

### Fish Shell Configuration

```nix
illogical-impulse.fish = {
  enable = true;
  enableStarship = true;  # Enable Starship prompt
  
  # Custom aliases
  aliases = {
    pamcan = "pacman";
    ls = "eza --icons";
    clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    q = "qs -c ii";
    # Add your own aliases here
  };
};
```

### Terminal Configuration

```nix
illogical-impulse.terminal = {
  default = "kitty";  # Default terminal emulator
  
  kitty = {
    enable = true;  # Deploy Kitty configuration
  };
};
```

### Theme Configuration

```nix
illogical-impulse.theme = {
  cursorTheme = "Bibata-Modern-Classic";
  gtkTheme = "adw-gtk3-dark";
  iconTheme = "breeze-dark";
};
```

### Configuration Files

```nix
illogical-impulse.configFiles = {
  enable = true;  # Deploy all configuration files from .config directory
};
```

When enabled, this option deploys configuration files to `~/.config` for:
- Hyprland (hyprland.conf, hypridle.conf, hyprlock.conf)
- Fish shell
- Kitty terminal
- Starship prompt
- Fuzzel launcher
- Wlogout
- Qt5/Qt6 themes (qt5ct, qt6ct, Kvantum)
- KDE applications (when kde.enable = true)
- XDG portals
- And more...

## Module Structure

The flake provides both a unified module (`homeManagerModules.default`) and individual component modules:

```nix
inputs.illogical-impulse.homeManagerModules = {
  default         # Unified module with all components
  audio           # Just audio dependencies
  basic           # Just basic utilities
  hyprland        # Just Hyprland packages
  # ... and so on
};
```

You can import individual modules if you only want specific components:

```nix
imports = [
  illogical-impulse.homeManagerModules.hyprland
  illogical-impulse.homeManagerModules.basic
];

illogical-impulse = {
  hyprland.enable = true;
  basic.enable = true;
};
```

## Customization

### Adding Custom Hyprland Configuration

The flake deploys the default configuration files but creates empty custom override files:

- `~/.config/hypr/custom/env.conf`
- `~/.config/hypr/custom/execs.conf`
- `~/.config/hypr/custom/general.conf`
- `~/.config/hypr/custom/keybinds.conf`
- `~/.config/hypr/custom/rules.conf`

Add your customizations to these files, or use the `extraConfig` option.

### Extending the Configuration

You can extend the configuration by adding your own Home Manager options alongside the Illogical Impulse configuration:

```nix
{
  illogical-impulse = {
    enable = true;
    hyprland.enable = true;
    # ... other options
  };

  # Your own Home Manager configuration
  home.packages = with pkgs; [
    firefox
    vscode
    # ... your packages
  ];

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "your.email@example.com";
  };
}
```

## Development

### Testing the Flake Locally

Clone the repository and test the configuration:

```bash
git clone https://github.com/Version33/dots-hyprland.git
cd dots-hyprland

# Check flake syntax
nix flake check

# Build the example configuration
nix build .#homeConfigurations.example-user.activationPackage

# Test in a VM or apply to your system
home-manager switch --flake .#yourusername
```

### Directory Structure

```
.
├── flake.nix              # Main flake definition
├── module.nix             # Unified Home Manager module
├── dist-nix/              # Individual component modules
│   ├── illogical-impulse-audio.nix
│   ├── illogical-impulse-hyprland.nix
│   └── ...
├── .config/               # Configuration files deployed by the flake
│   ├── hypr/
│   ├── fish/
│   ├── kitty/
│   └── ...
└── FLAKE-USAGE.md        # This file
```

## Troubleshooting

### Monitor Configuration Not Working

Make sure your monitor names are correct. List your monitors:

```bash
hyprctl monitors
```

Then use the exact names in your configuration.

### Configuration Files Not Deploying

Ensure `illogical-impulse.configFiles.enable = true` is set and that you've enabled the relevant component modules.

### Packages Not Available

Some packages from the Arch PKGBUILD versions may not be available in nixpkgs or may have different names. Check the individual module files in `dist-nix/` for notes about package availability.

## Contributing

Contributions are welcome! Please submit issues and pull requests to the main repository.

## License

See the main repository's LICENSE file for details.
