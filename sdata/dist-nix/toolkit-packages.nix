# Toolkit and framework dependencies
{ pkgs }:

{
  # KDE dialogs and utilities
  kdialog = pkgs.kdePackages.kdialog;

  # Qt6 framework and components
  qt6-5compat = pkgs.qt6.qt5compat;
  qt6-avif-image-plugin = pkgs.qt6.qtimageformats; # Includes AVIF support
  qt6-base = pkgs.qt6.qtbase;
  qt6-declarative = pkgs.qt6.qtdeclarative;
  qt6-imageformats = pkgs.qt6.qtimageformats;
  qt6-multimedia = pkgs.qt6.qtmultimedia;
  qt6-positioning = pkgs.qt6.qtpositioning;
  qt6-quicktimeline = pkgs.qt6.qtquicktimeline;
  qt6-sensors = pkgs.qt6.qtsensors;
  qt6-svg = pkgs.qt6.qtsvg;
  qt6-tools = pkgs.qt6.qttools;
  qt6-translations = pkgs.qt6.qttranslations;
  qt6-virtualkeyboard = pkgs.qt6.qtvirtualkeyboard;
  qt6-wayland = pkgs.qt6.qtwayland;

  # KDE frameworks
  syntax-highlighting = pkgs.kdePackages.syntax-highlighting;

  # Power management
  upower = pkgs.upower;

  # Input simulation tools
  wtype = pkgs.wtype;
  ydotool = pkgs.ydotool;
}
