# Illogical Impulse Hyprland related packages
# These packages are equivalent to dist-arch/illogical-impulse-hyprland/PKGBUILD
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.hyprland.enable = mkEnableOption "Illogical Impulse Hyprland dependencies";

  config = mkIf config.illogical-impulse.hyprland.enable {
    home.packages = [
      pkgs.hypridle
      pkgs.hyprcursor
      pkgs.hyprland
      pkgs.hyprland-qtutils
      # hyprland-qt-support - Not available in nixpkgs
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
