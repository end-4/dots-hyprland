# Illogical Impulse XDG Desktop Portals
# These packages are equivalent to dist-arch/illogical-impulse-portal/PKGBUILD
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.portal.enable = mkEnableOption "Illogical Impulse XDG Desktop Portal dependencies";

  config = mkIf config.illogical-impulse.portal.enable {
    home.packages = [
      pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
    ];
  };
}
