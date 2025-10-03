# Illogical Impulse GTK/Qt Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-toolkit/PKGBUILD
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.toolkit.enable = mkEnableOption "Illogical Impulse GTK/Qt toolkit dependencies";

  config = mkIf config.illogical-impulse.toolkit.enable {
    home.packages = [
      pkgs.kdialog
      pkgs.qt6.qt5compat
      # qt6-avif-image-plugin - May be available through qt6.qtimageformats
      pkgs.qt6.qtbase
      pkgs.qt6.qtdeclarative
      pkgs.qt6.qtimageformats
      pkgs.qt6.qtmultimedia
      pkgs.qt6.qtpositioning
      # qt6-quicktimeline - Part of qt6.qtdeclarative
      pkgs.qt6.qtsensors
      pkgs.qt6.qtsvg
      pkgs.qt6.qttools
      pkgs.qt6.qttranslations
      pkgs.qt6.qtvirtualkeyboard
      pkgs.qt6.qtwayland
      pkgs.kdePackages.syntax-highlighting
      pkgs.upower
      pkgs.wtype
      pkgs.ydotool
    ];
  };
}
