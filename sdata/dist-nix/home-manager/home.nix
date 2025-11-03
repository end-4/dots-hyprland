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
      inetutils libnotify
      ## Media related
      brightnessctl pavucontrol
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
      libcava #cava (Used in Quickshell config)
      lxqt.pavucontrol-qt #pavucontrol-qt (Used in Hyprland and Quickshell config)
      wireplumber #wireplumber (not explicitly used)
      pipewire #pipewire-pulse (not explicitly used)
	    libdbusmenu-gtk3 #libdbusmenu-gtk3 (not explicitly used)
	    playerctl #playerctl (Used in Hyprland and Quickshell config)


      ### illogical-impulse-backlight
      (geoclue2.override { withDemoAgent = true; }) #geoclue (which demo agent used in Quickshell config)
      brightnessctl #brightnessctl (Used in Hyprland and Quickshell config)
      ddcutil #ddcutil (Used in Quickshell config)


      ### illogical-impulse-basic
      #axel (Seems not available, however actually not needed cuz it's only used for install Bibata_Cursor in package-installers.sh)
      bc #bc (Used in quickshell/ii/scripts/colors/switchwall.sh for example) 
      uutils-coreutils-noprefix #coreutils (Too many executables involved, not sure where been used)
      cliphist #cliphist (Used in Hyprland and Quickshell config)
      cmake #cmake (Used in building quickshell and MicroTeX)
      curlFull #curl (Used in Quickshell config)
      wget #wget (Used in Quickshell config)
      ripgrep #ripgrep (Not sure where been used)
      jq #jq (Widely used)
      #meson (Actually not needed. It was used in building AGS.)
      xdg-user-dirs #xdg-user-dirs (Used in Hyprland and Quickshell config)
      rsync #rsync (Used in install script)
      yq-go #go-yq (Used in install script)


      ### illogical-impulse-bibata-modern-classic-bin
      bibata-cursors #https://github.com/ful1e5/Bibata_Cursor


      ### illogical-impulse-fonts-themes
      #adw-gtk-theme-git
      #breeze
      #breeze-plus
      #darkly-bin
      #eza
      #fish
      #fontconfig
      #kitty
      #matugen-bin
      #otf-space-grotesk
      #starship
      #ttf-gabarito-git
      #ttf-jetbrains-mono-nerd
      #ttf-material-symbols-variable-git
      #ttf-readex-pro
      #ttf-roboto-flex
      #ttf-rubik-vf
      #ttf-twemoji


      ### illogical-impulse-hyprland
      #hypridle
      #hyprcursor
      #hyprland (Need NixGL, included elsewhere)
      #hyprland-qtutils
      #hyprland-qt-support
      #hyprlang
      #hyprlock
      #hyprpicker
      #hyprsunset
      #hyprutils
      #hyprwayland-scanner
      #xdg-desktop-portal-hyprland
      wl-clipboard #wl-clipboard


      ### illogical-impulse-kde
      #bluedevil
      #gnome-keyring
      #networkmanager
      #plasma-nm
      #polkit-kde-agent
      #dolphin
      #systemsettings

      
      ### illogical-impulse-microtex-git
      # This package will be installed as /opt/MicroTeX and it
      #MicroTeX#https://github.com/NanoMichael/MicroTeX
      # It seems not available on search.nixos.org


      ### illogical-impulse-oneui4-icons-git
      #OneUI4-Icons#https://github.com/end-4/OneUI4-Icons


      ### illogical-impulse-portal
      #xdg-desktop-portal
      #xdg-desktop-portal-kde
      #xdg-desktop-portal-gtk
      #xdg-desktop-portal-hyprland


      ### illogical-impulse-python
      #clang
      #uv
      #gtk4
      #libadwaita
      #libsoup3
      #libportal-gtk4
      #gobject-introspection
      #sassc


      ### illogical-impulse-quickshell-git
      #_commit='db1777c20b936a86528c1095cbcb1ebd92801402'
      #url='https://git.outfoxxed.me/quickshell/quickshell'


      ### illogical-impulse-screencapture
      #hyprshot
      #slurp
      #swappy
      #tesseract
      #tesseract-data-eng
      #wf-recorder


      ### illogical-impulse-toolkit
      #kdialog
      #qt6-5compat 
      #qt6-avif-image-plugin
      #qt6-base
      #qt6-declarative
      #qt6-imageformats
      #qt6-multimedia
      #qt6-positioning
      #qt6-quicktimeline
      #qt6-sensors
      #qt6-svg
      #qt6-tools
      #qt6-translations
      #qt6-virtualkeyboard
      #qt6-wayland
      #syntax-highlighting
      #upower
      #wtype
      #ydotool


      ### illogical-impulse-widgets
      #fuzzel
      #glib2 # for `gsettings` it seems?
      #imagemagick
      #hypridle
      #hyprutils
      #hyprlock
      #hyprpicker
      #nm-connection-editor
      songrec #songrec (Used in Quickshell config)
      translate-shell #translate-shell (Used in Quickshell config)
      wlogout #wlogout (Used in Hyprland config)

    ]
    ++ [
    (config.lib.nixGL.wrap pkgs.hyprland)
    ];
  }//home_attrs;
}
