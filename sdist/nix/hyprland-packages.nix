# Hyprland compositor and related packages
{ pkgs }:

{
  # Hyprland core
  hyprland = pkgs.hyprland;

  # Hyprland utilities and components
  hyprcursor = pkgs.hyprcursor;
  hyprlang = pkgs.hyprlang;
  hyprsunset = pkgs.hyprsunset;
  hyprwayland-scanner = pkgs.hyprwayland-scanner;

  # Note: The following are already in widgets-packages.nix:
  # hypridle, hyprlock, hyprpicker, hyprutils

  # Note: The following are already in portal-packages.nix:
  # xdg-desktop-portal-hyprland

  # Note: The following are already in screencapture-packages.nix:
  wl-clipboard = pkgs.wl-clipboard;

  # Qt integration for Hyprland
  hyprland-qtutils = pkgs.hyprland-qtutils;
  hyprland-qt-support = pkgs.hyprland-qt-support;
}
