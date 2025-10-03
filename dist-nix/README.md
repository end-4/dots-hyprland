# Nix Package Definitions for Illogical Impulse Dotfiles

This directory contains Nix package definitions that correspond to the Arch Linux PKGBUILD files in `dist-arch/`.

## Files

Each `.nix` file defines a list of packages that can be installed using Nix package manager or home-manager:

- `illogical-impulse-audio.nix` - Audio-related dependencies
- `illogical-impulse-backlight.nix` - Backlight control dependencies
- `illogical-impulse-basic.nix` - Basic utility dependencies
- `illogical-impulse-bibata-modern-classic-bin.nix` - Bibata cursor theme
- `illogical-impulse-fonts-themes.nix` - Fonts and theming dependencies
- `illogical-impulse-hyprland.nix` - Hyprland-related packages
- `illogical-impulse-kde.nix` - KDE-related dependencies
- `illogical-impulse-microtex-git.nix` - MicroTeX dependencies
- `illogical-impulse-portal.nix` - XDG Desktop Portal dependencies
- `illogical-impulse-python.nix` - Python development dependencies
- `illogical-impulse-screencapture.nix` - Screenshot and recording tools
- `illogical-impulse-toolkit.nix` - GTK/Qt toolkit dependencies
- `illogical-impulse-widgets.nix` - Widget dependencies

## Usage

### With home-manager

You can import these files in your home-manager configuration:

```nix
{ pkgs, ... }:
{
  home.packages = 
    (import ./dist-nix/illogical-impulse-audio.nix { inherit pkgs; })
    ++ (import ./dist-nix/illogical-impulse-basic.nix { inherit pkgs; })
    ++ (import ./dist-nix/illogical-impulse-hyprland.nix { inherit pkgs; });
}
```

### With NixOS configuration

```nix
{ pkgs, ... }:
{
  environment.systemPackages = 
    (import ./dist-nix/illogical-impulse-audio.nix { inherit pkgs; })
    ++ (import ./dist-nix/illogical-impulse-basic.nix { inherit pkgs; });
}
```

## Notes

- Some packages from the Arch PKGBUILDs may not be available in stable nixpkgs or have different names. These are noted with comments in the respective files.
- AUR-specific packages (ending in `-git` or `-bin` in Arch) may require additional setup or overlays in Nix.
- The screen lock feature should be handled separately based on your distribution's package manager as noted in `install-deps.sh`.

## Status

This is a work in progress. The `install-deps.sh` script is currently WIP and will be updated to automate the installation process using these Nix files.
