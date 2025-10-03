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
      audio = import ./dist-nix/illogical-impulse-audio.nix;
      backlight = import ./dist-nix/illogical-impulse-backlight.nix;
      basic = import ./dist-nix/illogical-impulse-basic.nix;
      bibata-cursor = import ./dist-nix/illogical-impulse-bibata-modern-classic-bin.nix;
      fonts-themes = import ./dist-nix/illogical-impulse-fonts-themes.nix;
      hyprland = import ./dist-nix/illogical-impulse-hyprland.nix;
      kde = import ./dist-nix/illogical-impulse-kde.nix;
      microtex = import ./dist-nix/illogical-impulse-microtex-git.nix;
      oneui4-icons = import ./dist-nix/illogical-impulse-oneui4-icons-git.nix;
      portal = import ./dist-nix/illogical-impulse-portal.nix;
      python = import ./dist-nix/illogical-impulse-python.nix;
      screencapture = import ./dist-nix/illogical-impulse-screencapture.nix;
      toolkit = import ./dist-nix/illogical-impulse-toolkit.nix;
      widgets = import ./dist-nix/illogical-impulse-widgets.nix;
    };

    # Example home configuration
    # Users can use this as a template for their own configuration
    homeConfigurations."example-user" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      
      modules = [
        self.homeManagerModules.default
        {
          home = {
            username = "example-user";
            homeDirectory = "/home/example-user";
            stateVersion = "24.05";
          };

          # Enable the components you want
          illogical-impulse = {
            enable = true; # Master enable switch
            
            # Component enables
            audio.enable = true;
            backlight.enable = true;
            basic.enable = true;
            fonts-themes.enable = true;
            hyprland.enable = true;
            portal.enable = true;
            screencapture.enable = true;
            toolkit.enable = true;
            widgets.enable = true;
            
            # Optional components
            bibata-cursor.enable = false;
            kde.enable = false;
            microtex.enable = false;
            oneui4-icons.enable = false;
            python.enable = false;
          };
        }
      ];
    };
  };
}
