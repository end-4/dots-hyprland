# KDE-related packages
{ pkgs }:

{
  # KDE desktop and utilities
  bluedevil = pkgs.kdePackages.bluedevil;
  gnome-keyring = pkgs.gnome-keyring;
  networkmanager = pkgs.networkmanager;
  plasma-nm = pkgs.kdePackages.plasma-nm;
  polkit-kde-agent = pkgs.kdePackages.polkit-kde-agent-1;
  dolphin = pkgs.kdePackages.dolphin;
  systemsettings = pkgs.kdePackages.systemsettings;
  plasma-browser-integration = pkgs.kdePackages.plasma-browser-integration;
}
