# Widgets and UI components
{ pkgs }:

{
  # Application launcher
  fuzzel = pkgs.fuzzel;

  # GLib for gsettings and utilities
  glib = pkgs.glib;
  glib-networking = pkgs.glib-networking; # Often needed with glib

  # Image manipulation
  imagemagick = pkgs.imagemagick;

  # Hyprland utilities
  hypridle = pkgs.hypridle;
  hyprlock = pkgs.hyprlock;
  hyprpicker = pkgs.hyprpicker;
  hyprutils = pkgs.hyprutils;

  # Network manager GUI
  nm-connection-editor = pkgs.networkmanagerapplet;

  # Translation tool
  translate-shell = pkgs.translate-shell;

  # Logout menu
  wlogout = pkgs.wlogout;
}
