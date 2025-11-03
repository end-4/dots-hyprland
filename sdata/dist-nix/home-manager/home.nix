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
      # TODO: geoclue agent is used in .config/hypr/hyprland/scripts/start_geoclue_agent.sh with hardcoded path under /usr/ .
      # If installed by Nix, then the agent path will be ${cfg.package}/libexec/geoclue-2.0/demos/agent , where ${cfg.package} is defined by Nix, see https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/desktops/geoclue2.nix .
      # it won't work without futher tweaks.
      # geoclue2 # geoclue
      (geoclue2.override { withDemoAgent = true; })
      brightnessctl # brightnessctl
      ddcutil # ddcutil
    ]
    ++ [
    (config.lib.nixGL.wrap pkgs.hyprland)
    ];
  }//home_attrs;
}
