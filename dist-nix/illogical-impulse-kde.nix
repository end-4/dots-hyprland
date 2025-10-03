# Illogical Impulse KDE Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-kde/PKGBUILD
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.kde.enable = mkEnableOption "Illogical Impulse KDE dependencies";

  config = mkIf config.illogical-impulse.kde.enable {
    home.packages = [
      pkgs.bluedevil
      pkgs.gnome-keyring
      pkgs.networkmanager
      pkgs.plasma-nm
      pkgs.polkit-kde-agent
      pkgs.dolphin
      pkgs.systemsettings
    ];
  };
}
