{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.illogical-impulse;
in
{
  imports = [
    ./dist-nix/illogical-impulse-audio.nix
    ./dist-nix/illogical-impulse-backlight.nix
    ./dist-nix/illogical-impulse-basic.nix
    ./dist-nix/illogical-impulse-bibata-modern-classic-bin.nix
    ./dist-nix/illogical-impulse-fonts-themes.nix
    ./dist-nix/illogical-impulse-hyprland.nix
    ./dist-nix/illogical-impulse-kde.nix
    ./dist-nix/illogical-impulse-microtex-git.nix
    ./dist-nix/illogical-impulse-oneui4-icons-git.nix
    ./dist-nix/illogical-impulse-portal.nix
    ./dist-nix/illogical-impulse-python.nix
    ./dist-nix/illogical-impulse-screencapture.nix
    ./dist-nix/illogical-impulse-toolkit.nix
    ./dist-nix/illogical-impulse-widgets.nix
  ];

  options.illogical-impulse = {
    enable = mkEnableOption "Illogical Impulse dotfiles configuration";

    # Hyprland-specific options
    hyprland = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Hyprland window manager and related packages";
      };

      monitors = mkOption {
        type = types.listOf types.str;
        default = [ ",preferred,auto,1" ];
        description = ''
          Monitor configuration for Hyprland.
          Each string should be in the format: name,resolution,position,scale
          Example: "DP-1,1920x1080@60,0x0,1"
          Use ",preferred,auto,1" for automatic configuration.
        '';
      };

      workspaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Workspace configuration for Hyprland.
          Example: "1, monitor:DP-1, default:true"
        '';
      };

      autostart = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically start Hyprland on tty1";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration to append to hyprland.conf";
      };
    };

    # Fish shell configuration
    fish = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Fish shell configuration";
      };

      enableStarship = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Starship prompt";
      };

      aliases = mkOption {
        type = types.attrsOf types.str;
        default = {
          pamcan = "pacman";
          ls = "eza --icons";
          clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
          q = "qs -c ii";
        };
        description = "Fish shell aliases";
      };
    };

    # Terminal configuration
    terminal = {
      default = mkOption {
        type = types.str;
        default = "kitty";
        description = "Default terminal emulator";
      };

      kitty = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Kitty terminal configuration";
        };
      };
    };

    # Theming options
    theme = {
      cursorTheme = mkOption {
        type = types.str;
        default = "Bibata-Modern-Classic";
        description = "Cursor theme name";
      };

      gtkTheme = mkOption {
        type = types.str;
        default = "adw-gtk3-dark";
        description = "GTK theme name";
      };

      iconTheme = mkOption {
        type = types.str;
        default = "breeze-dark";
        description = "Icon theme name";
      };
    };

    # Configuration file deployment
    configFiles = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Deploy configuration files from .config directory";
      };
    };
  };

  config = mkIf cfg.enable {
    # Deploy Hyprland configuration files
    xdg.configFile = mkMerge [
      (mkIf (cfg.hyprland.enable && cfg.configFiles.enable) {
        "hypr/hyprland.conf".source = ./.config/hypr/hyprland.conf;
        "hypr/hypridle.conf".source = ./.config/hypr/hypridle.conf;
        "hypr/hyprlock.conf".source = ./.config/hypr/hyprlock.conf;
        
        # Hyprland subdirectory configs
        "hypr/hyprland/colors.conf".source = ./.config/hypr/hyprland/colors.conf;
        "hypr/hyprland/env.conf".source = ./.config/hypr/hyprland/env.conf;
        "hypr/hyprland/execs.conf".source = ./.config/hypr/hyprland/execs.conf;
        "hypr/hyprland/general.conf".source = ./.config/hypr/hyprland/general.conf;
        "hypr/hyprland/keybinds.conf".source = ./.config/hypr/hyprland/keybinds.conf;
        "hypr/hyprland/rules.conf".source = ./.config/hypr/hyprland/rules.conf;
        
        # Custom configs (empty by default for user customization)
        "hypr/custom/env.conf".text = "";
        "hypr/custom/execs.conf".text = "";
        "hypr/custom/general.conf".text = "";
        "hypr/custom/keybinds.conf".text = "";
        "hypr/custom/rules.conf".text = "";
        
        # Monitor configuration
        "hypr/monitors.conf".text = ''
          # Monitor configuration
          ${concatMapStrings (monitor: "monitor=${monitor}\n") cfg.hyprland.monitors}
        '';
        
        # Workspace configuration
        "hypr/workspaces.conf".text = ''
          # Workspace configuration
          ${concatMapStrings (workspace: "workspace=${workspace}\n") cfg.hyprland.workspaces}
        '';
      })

      # Deploy Fish configuration
      (mkIf (cfg.fish.enable && cfg.configFiles.enable) {
        "fish/config.fish".text = ''
          function fish_prompt -d "Write out the prompt"
              # This shows up as USER@HOST /home/user/ >, with the directory colored
              # $USER and $hostname are set by fish, so you can just use them
              # instead of using `whoami` and `hostname`
              printf '%s@%s %s%s%s > ' $USER $hostname \
                  (set_color $fish_color_cwd) (prompt_pwd) (set_color normal)
          end

          if status is-interactive # Commands to run in interactive sessions can go here

              # No greeting
              set fish_greeting

              ${optionalString cfg.fish.enableStarship ''
              # Use starship
              starship init fish | source
              if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
                  cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
              end
              ''}

              # Aliases
              ${concatStringsSep "\n    " (mapAttrsToList (name: value: "alias ${name} '${value}'") cfg.fish.aliases)}
              
          end
        '';

        "fish/auto-Hypr.fish" = mkIf cfg.hyprland.autostart {
          text = ''
            # Auto start Hyprland on tty1
            if test -z "$DISPLAY" ;and test "$XDG_VTNR" -eq 1
                mkdir -p ~/.cache
                exec Hyprland > ~/.cache/hyprland.log 2>&1
            end
          '';
        };
      })

      # Deploy Kitty configuration
      (mkIf (cfg.terminal.kitty.enable && cfg.configFiles.enable) {
        "kitty/kitty.conf".source = ./.config/kitty/kitty.conf;
        "kitty/scroll_mark.py".source = ./.config/kitty/scroll_mark.py;
        "kitty/search.py".source = ./.config/kitty/search.py;
      })

      # Deploy Starship configuration
      (mkIf (cfg.fish.enableStarship && cfg.configFiles.enable) {
        "starship.toml".source = ./.config/starship.toml;
      })

      # Deploy fuzzel configuration
      (mkIf (cfg.widgets.enable && cfg.configFiles.enable) {
        "fuzzel".source = ./.config/fuzzel;
      })

      # Deploy wlogout configuration
      (mkIf (cfg.widgets.enable && cfg.configFiles.enable) {
        "wlogout".source = ./.config/wlogout;
      })

      # Deploy foot terminal configuration
      (mkIf cfg.configFiles.enable {
        "foot".source = ./.config/foot;
      })

      # Deploy fontconfig
      (mkIf (cfg.fonts-themes.enable && cfg.configFiles.enable) {
        "fontconfig".source = ./.config/fontconfig;
      })

      # Deploy Qt configuration
      (mkIf (cfg.toolkit.enable && cfg.configFiles.enable) {
        "qt5ct".source = ./.config/qt5ct;
        "qt6ct".source = ./.config/qt6ct;
        "Kvantum".source = ./.config/Kvantum;
      })

      # Deploy KDE configuration files
      (mkIf (cfg.kde.enable && cfg.configFiles.enable) {
        "kdeglobals".source = ./.config/kdeglobals;
        "dolphinrc".source = ./.config/dolphinrc;
        "konsolerc".source = ./.config/konsolerc;
      })

      # Deploy Chromium/Chrome flags
      (mkIf cfg.configFiles.enable {
        "chrome-flags.conf".source = ./.config/chrome-flags.conf;
        "code-flags.conf".source = ./.config/code-flags.conf;
        "thorium-flags.conf".source = ./.config/thorium-flags.conf;
      })

      # Deploy XDG portal configuration
      (mkIf (cfg.portal.enable && cfg.configFiles.enable) {
        "xdg-desktop-portal".source = ./.config/xdg-desktop-portal;
      })
    ];

    # Enable Hyprland through home-manager if requested
    wayland.windowManager.hyprland = mkIf cfg.hyprland.enable {
      enable = true;
      xwayland.enable = true;
      systemd.enable = true;
    };

    # Enable Fish shell through home-manager
    programs.fish = mkIf cfg.fish.enable {
      enable = true;
    };

    # Enable Starship prompt
    programs.starship = mkIf cfg.fish.enableStarship {
      enable = true;
    };

    # Enable Kitty terminal
    programs.kitty = mkIf cfg.terminal.kitty.enable {
      enable = true;
    };
  };
}
