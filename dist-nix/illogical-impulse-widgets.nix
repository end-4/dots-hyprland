# Illogical Impulse Widget Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-widgets/PKGBUILD
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.widgets.enable = mkEnableOption "Illogical Impulse widget dependencies";

  config = mkIf config.illogical-impulse.widgets.enable {
    home.packages = [
      pkgs.fuzzel
      pkgs.glib
      pkgs.hypridle
      pkgs.hyprutils
      pkgs.hyprlock
      pkgs.hyprpicker
      pkgs.networkmanagerapplet
      pkgs.quickshell
      pkgs.translate-shell
      pkgs.wlogout
    ];
  };
}
