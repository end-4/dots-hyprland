{
  description = "end_4's Hyprland dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Custom package inputs
    breeze-plus = {
      url = "github:mjkim0727/breeze-plus";
      flake = false;
    };

    matugen = {
      url = "github:InioX/Matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gabarito = {
      url = "github:naipefoundry/gabarito";
      flake = false;
    };

    #microtex-src = {
    #  url = "github:NanoMichael/MicroTeX";
    #  flake = false;
    #};

    quickshell-src = {
      url = "github:quickshell-mirror/quickshell";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, home-manager, breeze-plus, matugen, gabarito, quickshell-src }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      # Import our modular packages
      basicPackages = import ./basic-packages.nix { inherit pkgs; };
      audioPackages = import ./audio-packages.nix { inherit pkgs; };
      backlightPackages = import ./backlight-packages.nix { inherit pkgs; };
      fontsThemesPackages = import ./fonts-themes-packages.nix {
        inherit pkgs breeze-plus matugen gabarito;
      };
      kdePackages = import ./kde-packages.nix { inherit pkgs; };
      portalPackages = import ./portal-packages.nix { inherit pkgs; };
      pythonPackages = import ./python-packages.nix { inherit pkgs; };
      screencapturePackages = import ./screencapture-packages.nix { inherit pkgs; };
      toolkitPackages = import ./toolkit-packages.nix { inherit pkgs; };
      widgetsPackages = import ./widgets-packages.nix { inherit pkgs; };
      hyprlandPackages = import ./hyprland-packages.nix { inherit pkgs; };
      #microtexPackages = import ./microtex-packages.nix { inherit pkgs microtex-src; };
      quickshellPackages = import ./quickshell-packages.nix { inherit pkgs lib quickshell-src; };

      # Combine all packages
      allPackages = basicPackages // audioPackages // backlightPackages // fontsThemesPackages // kdePackages // portalPackages // pythonPackages // screencapturePackages // toolkitPackages // widgetsPackages // hyprlandPackages // quickshellPackages;

      # Dotfiles configuration
      dotfilesConfig = {
        # Main configuration files
        xdg.configFile = {
          # Individual config files
          "chrome-flags.conf".source = ../../dots/.config/chrome-flags.conf;
          "code-flags.conf".source = ../../dots/.config/code-flags.conf;
          "darklyrc".source = ../../dots/.config/darklyrc;
          "dolphinrc".source = ../../dots/.config/dolphinrc;
          "kdeglobals".source = ../../dots/.config/kdeglobals;
          "konsolerc".source = ../../dots/.config/konsolerc;
          "starship.toml".source = ../../dots/.config/starship.toml;
          "thorium-flags.conf".source = ../../dots/.config/thorium-flags.conf;

          # Fontconfig
          #"fontconfig/conf.d".source = ../../dots/.config/fontconfig/conf.d;

          # Foot terminal
          "foot/foot.ini".source = ../../dots/.config/foot/foot.ini;

          # Fuzzel application launcher
          "fuzzel/fuzzel.ini".source = ../../dots/.config/fuzzel/fuzzel.ini;
          "fuzzel/fuzzel_theme.ini".source = ../../dots/.config/fuzzel/fuzzel_theme.ini;

          # Fish shell
          "fish/config.fish".source = ../../dots/.config/fish/config.fish;
          "fish/auto-Hypr.fish".source = ../../dots/.config/fish/auto-Hypr.fish;
          "fish/fish_variables".source = ../../dots/.config/fish/fish_variables;

          # Kitty terminal
          "kitty/kitty.conf".source = ../../dots/.config/kitty/kitty.conf;
          "kitty/scroll_mark.py".source = ../../dots/.config/kitty/scroll_mark.py;
          "kitty/search.py".source = ../../dots/.config/kitty/search.py;

          # KDE Material You Colors
          "kde-material-you-colors/config.conf".source = ../../dots/.config/kde-material-you-colors/config.conf;

          # Kvantum themes
          "Kvantum/kvantum.kvconfig".source = ../../dots/.config/Kvantum/kvantum.kvconfig;
          "Kvantum/Colloid/ColloidDark.kvconfig".source = ../../dots/.config/Kvantum/Colloid/ColloidDark.kvconfig;
          "Kvantum/Colloid/ColloidDark.svg".source = ../../dots/.config/Kvantum/Colloid/ColloidDark.svg;
          "Kvantum/Colloid/Colloid.kvconfig".source = ../../dots/.config/Kvantum/Colloid/Colloid.kvconfig;
          "Kvantum/Colloid/Colloid.svg".source = ../../dots/.config/Kvantum/Colloid/Colloid.svg;
          "Kvantum/MaterialAdw/MaterialAdw.kvconfig".source = ../../dots/.config/Kvantum/MaterialAdw/MaterialAdw.kvconfig;
          "Kvantum/MaterialAdw/MaterialAdw.svg".source = ../../dots/.config/Kvantum/MaterialAdw/MaterialAdw.svg;

          # Matugen theming
          "matugen/config.toml".source = ../../dots/.config/matugen/config.toml;
          "matugen/templates/ags".source = ../../dots/.config/matugen/templates/ags;
          "matugen/templates/colors.json".source = ../../dots/.config/matugen/templates/colors.json;
          "matugen/templates/fuzzel".source = ../../dots/.config/matugen/templates/fuzzel;
          "matugen/templates/gtk".source = ../../dots/.config/matugen/templates/gtk;
          "matugen/templates/hyprland".source = ../../dots/.config/matugen/templates/hyprland;
          "matugen/templates/kde".source = ../../dots/.config/matugen/templates/kde;
          "matugen/templates/wallpaper.txt".source = ../../dots/.config/matugen/templates/wallpaper.txt;

          # MPV media player
          "mpv/mpv.conf".source = ../../dots/.config/mpv/mpv.conf;

          # QT configuration
          "qt5ct/qt5ct.conf".source = ../../dots/.config/qt5ct/qt5ct.conf;
          "qt6ct/qt6ct.conf".source = ../../dots/.config/qt6ct/qt6ct.conf;

          # Quickshell
          "quickshell/ii/assets".source = ../../dots/.config/quickshell/ii/assets;
          "quickshell/ii/defaults".source = ../../dots/.config/quickshell/ii/defaults;
          "quickshell/ii/GlobalStates.qml".source = ../../dots/.config/quickshell/ii/GlobalStates.qml;
          "quickshell/ii/killDialog.qml".source = ../../dots/.config/quickshell/ii/killDialog.qml;
          "quickshell/ii/modules".source = ../../dots/.config/quickshell/ii/modules;
          "quickshell/ii/.qmlformat.ini".source = ../../dots/.config/quickshell/ii/.qmlformat.ini;
          "quickshell/ii/ReloadPopup.qml".source = ../../dots/.config/quickshell/ii/ReloadPopup.qml;
          "quickshell/ii/scripts".source = ../../dots/.config/quickshell/ii/scripts;
          "quickshell/ii/services".source = ../../dots/.config/quickshell/ii/services;
          "quickshell/ii/settings.qml".source = ../../dots/.config/quickshell/ii/settings.qml;
          "quickshell/ii/shell.qml".source = ../../dots/.config/quickshell/ii/shell.qml;
          "quickshell/ii/translations".source = ../../dots/.config/quickshell/ii/translations;
          "quickshell/ii/welcome.qml".source = ../../dots/.config/quickshell/ii/welcome.qml;

          # Wlogout
          "wlogout/layout".source = ../../dots/.config/wlogout/layout;
          "wlogout/style.css".source = ../../dots/.config/wlogout/style.css;

          # XDG Desktop Portal
          "xdg-desktop-portal/hyprland-portals.conf".source = ../../dots/.config/xdg-desktop-portal/hyprland-portals.conf;

          # ZSH configuration
          "zshrc.d/auto-Hypr.sh".source = ../../dots/.config/zshrc.d/auto-Hypr.sh;
          "zshrc.d/dots-hyprland.zsh".source = ../../dots/.config/zshrc.d/dots-hyprland.zsh;
          "zshrc.d/shortcuts.zsh".source = ../../dots/.config/zshrc.d/shortcuts.zsh;

          # Hyprland configuration - with special handling for custom files
          "hypr/hyprland.conf".source = ../../dots/.config/hypr/hyprland.conf;
          "hypr/hypridle.conf".source = ../../dots/.config/hypr/hypridle.conf;
          "hypr/hyprlock.conf".source = ../../dots/.config/hypr/hyprlock.conf;
          "hypr/monitors.conf".source = ../../dots/.config/hypr/monitors.conf;
          "hypr/workspaces.conf".source = ../../dots/.config/hypr/workspaces.conf;

          # Hyprland subdirectories
          "hypr/hyprland/colors.conf".source = ../../dots/.config/hypr/hyprland/colors.conf;
          "hypr/hyprland/env.conf".source = ../../dots/.config/hypr/hyprland/env.conf;
          "hypr/hyprland/execs.conf".source = ../../dots/.config/hypr/hyprland/execs.conf;
          "hypr/hyprland/general.conf".source = ../../dots/.config/hypr/hyprland/general.conf;
          "hypr/hyprland/keybinds.conf".source = ../../dots/.config/hypr/hyprland/keybinds.conf;
          "hypr/hyprland/rules.conf".source = ../../dots/.config/hypr/hyprland/rules.conf;
          "hypr/hyprland/scripts".source = ../../dots/.config/hypr/hyprland/scripts;

          # Hyprlock
          "hypr/hyprlock/check-capslock.sh".source = ../../dots/.config/hypr/hyprlock/check-capslock.sh;
          "hypr/hyprlock/colors.conf".source = ../../dots/.config/hypr/hyprlock/colors.conf;
          "hypr/hyprlock/status.sh".source = ../../dots/.config/hypr/hyprlock/status.sh;

          # Hyprland custom configuration (optional - user can modify these)
          "hypr/custom/env.conf".source = ../../dots/.config/hypr/custom/env.conf;
          "hypr/custom/execs.conf".source = ../../dots/.config/hypr/custom/execs.conf;
          "hypr/custom/general.conf".source = ../../dots/.config/hypr/custom/general.conf;
          "hypr/custom/keybinds.conf".source = ../../dots/.config/hypr/custom/keybinds.conf;
          "hypr/custom/rules.conf".source = ../../dots/.config/hypr/custom/rules.conf;
          "hypr/custom/scripts".source = ../../dots/.config/hypr/custom/scripts;
        };

        # Local share files
        xdg.dataFile = {
          "icons/illogical-impulse.svg".source = ../../dots/.local/share/icons/illogical-impulse.svg;
          #"konsole/Profile 1.profile".source = "../../dots/.local/share/konsole/Profile\ 1.profile";
        };

        # ZSH configuration - source the dots-hyprland file
        programs.zsh = {
          enable = true;
          initExtra = ''
            source ${../../dots/.config/zshrc.d/dots-hyprland.zsh}
          '';
        };
      };
    in
    {
      # Define packages
      packages.${system} = allPackages // {
        # Create a package set containing all tools
        my-hyprland-tools = pkgs.symlinkJoin {
          name = "my-hyprland-tools";
          paths = builtins.attrValues allPackages;
        };

        # Set default to the complete package set
        default = self.packages.${system}.my-hyprland-tools;
      };

      # Development shell with all packages
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = builtins.attrValues allPackages;
      };


      # Home Manager configurations
      homeConfigurations = {
        # FIXME: change username
        "your-username" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ({ config, lib, ... }:
              {
                # Basic configuration
                # FIXME: change username
                home.username = "your-username";
                home.homeDirectory = "/home/your-username";
                programs.home-manager.enable = true;
                home.stateVersion = "25.05";

                # Install all packages + fonts
                home.packages = builtins.attrValues allPackages;

                # Session variables
                home.sessionVariables = {
                  # Wayland and desktop variables
                  NIXOS_OZONE_WL = "1";
                  QT_QPA_PLATFORM = "wayland";
                  SDL_VIDEODRIVER = "wayland";
                  XDG_CURRENT_DESKTOP = "Hyprland";
                  XDG_SESSION_TYPE = "wayland";
                  XDG_SESSION_DESKTOP = "Hyprland";

                  # XDG base directories
                  XDG_CONFIG_HOME = "$HOME/.config";
                  XDG_DATA_HOME = "$HOME/.local/share";
                  XDG_BIN_HOME = "$HOME/.local/bin";
                  XDG_CACHE_HOME = "$HOME/.cache";

                  # Application-specific variables
                  ILLOGICAL_IMPULSE_VIRTUAL_ENV = "$HOME/.local/state/quickshell/.venv";

                  # Cursor theme
                  XCURSOR_THEME = "Bibata-Modern-Classic";
                  XCURSOR_SIZE = "24";

                  # Portal hints
                  NIXOS_XDG_OPEN_USE_PORTAL = "1";
                };

                # Qt configuration
                qt = {
                  enable = true;
                  platformTheme = "qtct";
                  style.name = "Darkly";
                };

                # Font configuration
                fonts.fontconfig = {
                  enable = true;
                  defaultFonts = {
                    serif = [ "Readex Pro" ];
                    sansSerif = [ "Readex Pro" ];
                    monospace = [ "JetBrains Mono Nerd Font" ];
                    emoji = [ "Twemoji" ];
                  };
                };

                # GTK configuration
                gtk = {
                  enable = true;
                  theme = {
                    name = "Breeze-plus";
                    #package = pkgs.libsForQt5.breeze-gtk;
                  };
                  cursorTheme = {
                    name = "Bibata-Modern-Classic";
                    package = pkgs.bibata-cursors;
                  };
                  iconTheme = {
                    name = "Papirus-Dark";
                    package = pkgs.papirus-icon-theme;
                  };
                };


                # Import the dotfiles configuration
                imports = [ dotfilesConfig ];

                # Hyprland configuration
                wayland.windowManager.hyprland = {
                  enable = true;
                  package = hyprlandPackages.hyprland;
                  xwayland.enable = true;
                  # systemd integration for auto-reload
                  systemdIntegration = true;
                };

                # Fish shell configuration
                #programs.fish.enable = true;

                # Systemd user services
                systemd.user.services = {
                  # Quickshell service
                  quickshell = {
                    Unit = {
                      Description = "QuickShell Compositor";
                      After = [ "graphical-session.target" ];
                      PartOf = [ "graphical-session.target" ];
                    };

                    Service = {
                      Type = "simple";
                      ExecStart = "${quickshellPackages.quickshell}/bin/quickshell";
                      Restart = "on-failure";
                      RestartSec = 1;
                      TimeoutStopSec = 10;
                      Environment = [
                        "ILLOGICAL_IMPULSE_VIRTUAL_ENV=$HOME/.local/state/quickshell/.venv"
                      ];
                    };

                    Install = {
                      WantedBy = [ "graphical-session.target" ];
                    };
                  };

                  # Polkit agent (for authentication dialogs)
                  polkit-gnome-authentication-agent-1 = lib.mkIf (pkgs.stdenv.isLinux) {
                    Unit = {
                      Description = "polkit-gnome-authentication-agent-1";
                      After = [ "graphical-session.target" ];
                    };

                    Service = {
                      Type = "simple";
                      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
                      Restart = "on-failure";
                      RestartSec = 1;
                      TimeoutStopSec = 10;
                    };

                    Install = {
                      WantedBy = [ "graphical-session.target" ];
                    };
                  };
                };

                # User services managed by Home Manager
                services = {
                  # GNOME Keyring daemon
                  gnome-keyring = {
                    enable = true;
                    components = [ "secrets" "ssh" ];
                  };
                };

                # Home Manager specific options
                home = {
                  # Session variables that need to be available early
                  sessionPath = [
                    "$HOME/.local/bin"
                    "$XDG_BIN_HOME"
                  ];

                  # Shell aliases
                  shellAliases = {
                    hm = "home-manager";
                  };
                };
              })
          ];
        };
      };

      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
