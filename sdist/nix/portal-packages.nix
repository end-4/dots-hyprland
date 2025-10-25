# Desktop portal packages
{ pkgs }:

{
  # Desktop portals
  xdg-desktop-portal = pkgs.xdg-desktop-portal;
  xdg-desktop-portal-kde = pkgs.kdePackages.xdg-desktop-portal-kde;
  xdg-desktop-portal-gtk = pkgs.xdg-desktop-portal-gtk;
  xdg-desktop-portal-hyprland = pkgs.xdg-desktop-portal-hyprland;
}
