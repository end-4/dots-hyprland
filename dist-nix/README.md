# Nix Package Definitions for Illogical Impulse Dotfiles

This directory contains Nix module definitions that correspond to the Arch Linux PKGBUILD files in `dist-arch/`.

## Files

Each `.nix` file is a home-manager module that can be imported and enabled:

- `illogical-impulse-audio.nix` - Audio-related dependencies
- `illogical-impulse-backlight.nix` - Backlight control dependencies
- `illogical-impulse-basic.nix` - Basic utility dependencies
- `illogical-impulse-bibata-modern-classic-bin.nix` - Bibata cursor theme
- `illogical-impulse-fonts-themes.nix` - Fonts and theming dependencies
- `illogical-impulse-hyprland.nix` - Hyprland-related packages
- `illogical-impulse-kde.nix` - KDE-related dependencies
- `illogical-impulse-microtex-git.nix` - MicroTeX dependencies
- `illogical-impulse-oneui4-icons-git.nix` - OneUI4 Icons (optional, not installed by default)
- `illogical-impulse-portal.nix` - XDG Desktop Portal dependencies
- `illogical-impulse-python.nix` - Python development dependencies
- `illogical-impulse-screencapture.nix` - Screenshot and recording tools
- `illogical-impulse-toolkit.nix` - GTK/Qt toolkit dependencies
- `illogical-impulse-widgets.nix` - Widget dependencies

## Usage

### With home-manager

Import these modules in your home-manager configuration and enable as needed:

```nix
{ config, pkgs, ... }:
{
  imports = [
    ./dist-nix/illogical-impulse-audio.nix
    ./dist-nix/illogical-impulse-basic.nix
    ./dist-nix/illogical-impulse-hyprland.nix
    # Add other modules as needed
  ];

  # Enable the modules you want
  illogical-impulse = {
    audio.enable = true;
    basic.enable = true;
    hyprland.enable = true;
  };
}
```

### With flake.nix

In a flake-based configuration:

```nix
{
  description = "My home configuration";

  inputs = {
    nixpkgs.url = "github:nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations."username" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        ./dist-nix/illogical-impulse-audio.nix
        ./dist-nix/illogical-impulse-basic.nix
        # Import other modules as needed
        {
          illogical-impulse = {
            audio.enable = true;
            basic.enable = true;
            # Enable other modules as needed
          };
        }
      ];
    };
  };
}
```

## Module Structure

Each module follows the standard Nix module pattern:

```nix
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.<name>.enable = mkEnableOption "description";

  config = mkIf config.illogical-impulse.<name>.enable {
    home.packages = [ /* packages */ ];
  };
}
```

This allows you to selectively enable only the dependency groups you need.

## Notes

- Some packages from the Arch PKGBUILDs may not be available in stable nixpkgs or have different names. These are noted with comments in the respective files.
- AUR-specific packages (ending in `-git` or `-bin` in Arch) may require additional setup or overlays in Nix.
- The screen lock feature should be handled separately based on your distribution's package manager as noted in `install-deps.sh`.

## Status

This is a work in progress. The `install-deps.sh` script is currently WIP and will be updated to automate the installation process using these Nix modules.
