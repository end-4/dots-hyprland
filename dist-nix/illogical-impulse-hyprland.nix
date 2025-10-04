# Illogical Impulse Hyprland related packages
# These packages are equivalent to dist-arch/illogical-impulse-hyprland/PKGBUILD
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.illogical-impulse.hyprland;
in
{
  options.illogical-impulse.hyprland = {
    enable = mkEnableOption "Illogical Impulse Hyprland dependencies";

    # Package installation
    package = mkOption {
      type = types.package;
      default = pkgs.hyprland;
      description = "The Hyprland package to use";
    };

    # Monitor configuration
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

    # Workspace configuration
    workspaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Workspace configuration for Hyprland.
        Example: "1, monitor:DP-1, default:true"
      '';
    };

    # Extra configuration
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration to append to hyprland.conf";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.hypridle
      pkgs.hyprcursor
      cfg.package
      pkgs.hyprland-qtutils
      pgks.hyprland-qt-support
      pkgs.hyprlang
      pkgs.hyprlock
      pkgs.hyprpicker
      pkgs.hyprsunset
      pkgs.hyprutils
      pkgs.hyprwayland-scanner
      pkgs.xdg-desktop-portal-hyprland
      pkgs.wl-clipboard
    ];
  };
}

