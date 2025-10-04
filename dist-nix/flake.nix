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
    # Home Manager module for the dotfiles
    homeManagerModules.default = import ./module.nix;
    
    # Convenience outputs for all individual modules
    homeManagerModules = {
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

    # Example home configuration
    # Users can use this as a template for their own configuration
    # homeConfigurations."example-user" = home-manager.lib.homeManagerConfiguration {
    #   pkgs = nixpkgs.legacyPackages.x86_64-linux;
      
    #   modules = [
    #     self.homeManagerModules.default
    #     {
    #       home = {
    #         username = "example-user";
    #         homeDirectory = "/home/example-user";
    #         stateVersion = "25.05";
    #       };

    #       # Enable the components you want
    #       illogical-impulse = {
    #         enable = true; # Master enable switch
            
    #         # Component enables
    #         audio.enable = true;
    #         backlight.enable = true;
    #         basic.enable = true;
    #         fonts-themes.enable = true;
    #         hyprland = {
    #           enable = true;
    #           # Configure monitors (optional)
    #           monitors = [ ",preferred,auto,1" ];
    #           # workspaces = [ ];
    #         };
    #         portal.enable = true;
    #         screencapture.enable = true;
    #         toolkit.enable = true;
    #         widgets.enable = true;
            
    #         # Optional components
    #         bibata-cursor.enable = false;
    #         kde.enable = false;
    #         microtex.enable = false;
    #         oneui4-icons.enable = false;
    #         python.enable = false;
            
    #         # Fish shell configuration
    #         fish = {
    #           enable = true;
    #           enableStarship = true;
    #           autostart.hyprland = true;
    #         };
            
    #         # Terminal configuration
    #         terminal = {
    #           default = "kitty";
    #           kitty.enable = true;
    #         };
    #       };
    #     }
    #   ];
    # };
  };
}
