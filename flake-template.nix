{
  description = "Example Home Manager configuration using Illogical Impulse dotfiles";

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
    homeConfigurations = {
      # Replace "yourusername" with your actual username
      "yourusername" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        
        modules = [
          illogical-impulse.homeManagerModules.default
          {
            home = {
              username = "yourusername";
              homeDirectory = "/home/yourusername";
              stateVersion = "24.05"; # Set this to your NixOS version
            };

            # Configure Illogical Impulse dotfiles
            illogical-impulse = {
              enable = true; # Master enable switch
              
              # Essential components - enable the ones you want
              audio.enable = true;           # Audio packages (pavucontrol, playerctl, etc.)
              basic.enable = true;           # Basic utilities (curl, wget, jq, etc.)
              fonts-themes.enable = true;    # Fonts and themes
              portal.enable = true;          # XDG Desktop Portals
              screencapture.enable = true;   # Screenshot and recording tools
              toolkit.enable = true;         # Qt/GTK libraries
              widgets.enable = true;         # Widget system dependencies
              
              # Hyprland configuration
              hyprland = {
                enable = true;
                
                # Monitor configuration - customize for your setup
                monitors = [
                  ",preferred,auto,1"          # Auto-detect all monitors
                  # Examples for specific monitors:
                  # "DP-1,1920x1080@60,0x0,1"  # Primary monitor
                  # "HDMI-A-1,1920x1080@60,1920x0,1"  # Secondary monitor
                ];
                
                # Workspace configuration (optional)
                workspaces = [
                  # "1, monitor:DP-1, default:true"
                ];
                
                # Add extra Hyprland config (optional)
                extraConfig = "";
              };
              
              # Optional components - enable as needed
              backlight.enable = false;      # Backlight control (for laptops)
              kde.enable = false;            # KDE applications
              python.enable = false;         # Python development tools
              bibata-cursor.enable = false;  # Bibata cursor theme
              microtex.enable = false;       # MicroTeX math rendering
              oneui4-icons.enable = false;   # OneUI4 icon theme
              
              # Fish shell configuration
              fish = {
                enable = true;
                enableStarship = true;       # Enable Starship prompt
                
                # Auto-start Hyprland on tty1
                autostart.hyprland = true;
                
                # Custom aliases
                aliases = {
                  # Default aliases
                  pamcan = "pacman";
                  ls = "eza --icons";
                  clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
                  q = "qs -c ii";
                  
                  # Add your own aliases here
                  # ll = "ls -la";
                  # gs = "git status";
                };
              };
              
              # Terminal configuration
              terminal = {
                default = "kitty";           # Default terminal emulator
                kitty.enable = true;         # Deploy Kitty config
              };
              
              # Theme configuration (provided by fonts-themes module)
              fonts-themes = {
                cursorTheme = "Bibata-Modern-Classic";
                gtkTheme = "adw-gtk3-dark";
                iconTheme = "breeze-dark";
              };
              
              # Configuration file deployment
              configFiles.enable = true;     # Deploy all config files from .config
            };

            # Add your own packages here
            home.packages = with pkgs; [
              # Add any additional packages you want
              # firefox
              # vscode
            ];

            # Additional Home Manager configuration
            # Add your own Git, SSH, or other program configurations here
            # programs.git = {
            #   enable = true;
            #   userName = "Your Name";
            #   userEmail = "your.email@example.com";
            # };
          }
        ];
      };
    };
  };
}
