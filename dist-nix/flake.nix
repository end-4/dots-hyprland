{
  description = "Illogical Impulse Dotfiles - A comprehensive Hyprland configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    # Home Manager modules for the dotfiles
    # Note: 'homeManagerModules' is a conventional output used by Home Manager users,
    # but it's not a standard Nix flake output, so Nix will warn about it being unknown.
    # That warning is harmless and can be safely ignored.
    homeManagerModules = {
      default = import ./module.nix;

      # Convenience outputs for all individual modules
      illogical-impulse = import ./module.nix;
      audio = import ./illogical-impulse-audio.nix;
      backlight = import ./illogical-impulse-backlight.nix;
      basic = import ./illogical-impulse-basic.nix;
      bibata-cursor = import ./illogical-impulse-bibata-modern-classic-bin.nix;
      fonts-themes = import ./illogical-impulse-fonts-themes.nix;
      hyprland = import ./illogical-impulse-hyprland.nix;
      kde = import ./illogical-impulse-kde.nix;
      microtex = import ./illogical-impulse-microtex-git.nix;
      oneui4-icons = import ./illogical-impulse-oneui4-icons-git.nix;
      portal = import ./illogical-impulse-portal.nix;
      python = import ./illogical-impulse-python.nix;
      screencapture = import ./illogical-impulse-screencapture.nix;
      toolkit = import ./illogical-impulse-toolkit.nix;
      widgets = import ./illogical-impulse-widgets.nix;
    };
  };
}