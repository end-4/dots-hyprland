{ config, lib, pkgs, nixgl, home_attrs, ... }:
{
  programs.home-manager.enable = true;
  nixGL.packages = nixgl.packages;
  nixGL.defaultWrapper = "mesa";

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [
        "gnome"
      ];
    };
  };
  ## Allow fontconfig to discover fonts in home.packages
  fonts.fontconfig.enable = true;

  # home.sessionVariables.NIXOS_OZONE_WL = "1";
  wayland.windowManager.hyprland = {
    ## Make sure home-manager not generate ~/.config/hypr/hyprland.conf
    systemd.enable = false; plugins = []; settings = {}; extraConfig = "";
    enable = true;
    ## Use NixGL
    package = config.lib.nixGL.wrap pkgs.hyprland;
  };

  home = {
    packages = with pkgs; [
      ##### Sure #####
      ## Basic cli tool
      ## inetutils: provides hostname, ifconfig, ping, etc.
      ## libnotify: provides notify-send
      jq rsync inetutils libnotify
      ## Media related
      brightnessctl pavucontrol
      ## Clipboard/Emoji
      wl-clipboard cliphist
      ## Terminal and shell
      foot cowsay lolcat

      ##### Fonts/Icons/Cursors/Decoration #####
      fontconfig

      ##### Other basic things #####
      dbus xorg.xlsclients networkmanager

      ##### Not work, to be solved #####
      # swaylock pamtester
      

      # TODO: migrate all packages from dist-arch. Note that for each package, must know why it's needed and how it's used specifically, cuz things may be need tweak to properly use the package installed by Nix, especially those have hardcoded path /usr/* .
      ### illogical-impulse-audio
      libcava #cava
      lxqt.pavucontrol-qt #pavucontrol-qt
      wireplumber #wireplumber (not explicitly used)
      pipewire #pipewire-pulse
	    libdbusmenu-gtk3 #libdbusmenu-gtk3 (not explicitly used)
	    playerctl #playerctl

      ### illogical-impulse-backlight
      # TODO: geoclue is used in https://github.com/end-4/dots-hyprland/blob/0551c010b586dbf5578c32de2735698cca0801a7/dots/.config/hypr/hyprland/scripts/start_geoclue_agent.sh with hardcoded absolute path to search the agent. Below will not work without futher tweaks in that start_geoclue_agent.sh
      geoclue2 # geoclue
      brightnessctl # brightnessctl
      ddcutil # ddcutil
    ];
  }//home_attrs;
}
