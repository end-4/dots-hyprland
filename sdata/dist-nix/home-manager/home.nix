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
      kdePackages.xdg-desktop-portal-kde
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
      foot # Used in Quickshell and Hyprland config; its config is also included

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
      #axel#axel (TODOrm: actually not needed cuz it's only used for install Bibata_Cursor in package-installers.sh)
      bc #bc (Used in quickshell/ii/scripts/colors/switchwall.sh for example) 
      uutils-coreutils-noprefix #coreutils (Too many executables involved, not sure where been used)
      cliphist #cliphist (Used in Hyprland and Quickshell config)
      cmake #cmake (Used in building quickshell and MicroTeX)
      curlFull #curl (Used in Quickshell config)
      wget #wget (Used in Quickshell config)
      ripgrep #ripgrep (Not sure where been used)
      jq #jq (Widely used)
      #meson (TODOrm: Actually not needed. It was used in building AGS.)
      xdg-user-dirs #xdg-user-dirs (Used in Hyprland and Quickshell config)
      rsync #rsync (Used in install script)
      yq-go #go-yq (Used in install script)


      ### illogical-impulse-bibata-modern-classic-bin
      bibata-cursors #https://github.com/ful1e5/Bibata_Cursor (Used in Hyprland config, not necessary)


      ### illogical-impulse-fonts-themes
      adw-gtk3 #adw-gtk-theme-git (https://github.com/lassekongo83/adw-gtk3) (Used in Quickshell config)
      kdePackages.breeze kdePackages.breeze-icons #breeze (Used in kdeglobals config)
      #breeze-plus (https://github.com/mjkim0727/breeze-plus) (TODO: Not available as nixpkg) (Used in kde-material-you-colors config)
      #darkly-bin (TODOrm: seems not being used?)
      eza #eza (Used in Fish config: `alias ls 'eza --icons'`)
      #fish (Probably should not install via Nix)
      fontconfig #fontconfig (Basic thing)
      kitty #kitty (Used in fuzzel, Hyprland, kdeglobals and Quickshell config; kitty config is also included as dots)
      matugen #matugen-bin (Used in Quickshell)
      #otf-space-grotesk (https://events.ccc.de/congress/2024/infos/styleguide.html) (TODO: Not available as Nixpkg) (Used in Quickshell and matugen config)
      starship #starship (Used in Fish config)
      #ttf-gabarito-git (Font name: Gabarito) (Used in fuzzel and Quickshell config) (TODO: Not available as Nixpkg)
      nerd-fonts.jetbrains-mono #ttf-jetbrains-mono-nerd (Font name: JetBrains Mono NF, JetBrainsMono Nerd Font) (Used in foot, kdeglobals, kitty, qt5ct, qt6ct and Quickshell config)
      material-symbols #ttf-material-symbols-variable-git (Font name: Material Symbols Rounded, Material Symbols Outlined) (Used in Hyprland, matugen, Quickshell and wlogout config)
      #ttf-readex-pro (Font name: Readex Pro) (Used in Quickshell config) (TODO: seems not available as nixpkg)
      roboto-flex #ttf-roboto-flex (Font name: Roboto Flex) (Used in Hyprland, matugen and Quickshell config)
      rubik #ttf-rubik-vf (Font name: Rubik, Rubik Light) (Used in Hyprland, kdeglobals, matugen, qt5ct, qt6ct and Quickshell config)
      twemoji-color-font #ttf-twemoji (Not explicitly used, but it may help as fallback for displaying emoji charaters)


      ### illogical-impulse-hyprland
      hypridle #hypridle (Used for loginctl to lock session)
      #hyprcursor (TODOrm: Seems not being used?)
      #hyprland (Need NixGL, included elsewhere)
      #hyprland-qtutils (TODOrm: Not needed, it's already a dependency of Hyprland itself, and it's not being used anywhere in this repo)
      #hyprland-qt-support (TODOrm: Not needed, it's already a dep of hyprland-qtutils which is a dep of Hyprland, and it's not being used anywhere in this repo)
      #hyprlang (TODOrm: Not needed, it's already a dependency of Hyprland, hypridle, etc.)
      #hyprlock (Should not be installed via Nix)
      hyprpicker #hyprpicker (Used in Hyprland and Quickshell config)
      hyprsunset #hyprsunset (Used in Quickshell config)
      #hyprutils #hyprutils (TODOrm: Not needed, it's already a dep of Hyprland and not being used anywhere in this repo)
      #hyprwayland-scanner (TODOrm: Not needed, it's already a dep of Hyprland and not being used anywhere in this repo)
      #xdg-desktop-portal-hyprland (DUPLICATE)
      wl-clipboard #wl-clipboard (Surely needed)


      ### illogical-impulse-kde
      kdePackages.bluedevil #bluedevil (Seems not being used anywhere, maybe a part of KDE settings panel)
      #gnome-keyring #gnome-keyring (TODO: Maybe should not be installed by Nix) (Provide executable gnome-keyring-daemon, used in Hyprland and Quickshell config)
      networkmanager #networkmanager
      kdePackages.plasma-nm #plasma-nm (Seems not being used anywhere, maybe a part of KDE settings panel)
      #polkit-kde-agent (TODO: Maybe should not install by Nix)
      kdePackages.dolphin #dolphin (Used in Hyprland and Quickshell config)
      kdePackages.systemsettings #systemsettings (Used in Hyprland keybinds.conf)

      
      ### illogical-impulse-microtex-git
      # This package will be installed as /opt/MicroTeX
      #MicroTeX#https://github.com/NanoMichael/MicroTeX
      # TODO: Not available as nixpkg


      ### illogical-impulse-oneui4-icons-git
      #OneUI4-Icons#https://github.com/end-4/OneUI4-Icons
      # TODO: Custom repo, need to make a package


      ### illogical-impulse-portal
      #xdg-desktop-portal (Included elsewhere)
      #xdg-desktop-portal-kde (Included elsewhere)
      #xdg-desktop-portal-gtk (Included elsewhere)
      #xdg-desktop-portal-hyprland (Included elsewhere)


      ### illogical-impulse-python
      clang #clang (Some python package may need this to be built, e.g. #1235)
      uv #uv (Used for python venv)
      gtk4 #gtk4 (Not explicitly used)
      libadwaita #libadwaita (Not explicitly used)
      libsoup_3 #libsoup3 (Not explicitly used)
      libportal-gtk4 #libportal-gtk4 (Not explicitly used)
      gobject-introspection #gobject-introspection (Not explicitly used)
      #sassc (TODOrm: Not used anymore)


      ### illogical-impulse-quickshell-git
      # TODO: maybe Quickshell uses GPU acceleration, which means NixGL is applicable
      quickshell.packages.x86_64-linux.default


      ### illogical-impulse-screencapture
      hyprshot #hyprshot (Used in Hyprland keybinds.conf as fallback)
      slurp #slurp (Used in Hyprland and Quickshell config)
      swappy #swappy (Used in Quickshell config)
      tesseract #tesseract (Used in Quickshell and Hyprland config)
      #tesseract-data-eng (Used as data for tesseract) (TODO: Seems not available as nixpkg)
      wf-recorder #wf-recorder (Used in Quickshell config)


      ### illogical-impulse-toolkit
      kdePackages.kdialog #kdialog (Used in Quickshell config)
      # TODO: Deal with qt6 things, see https://nixos.wiki/wiki/Qt
      #qt6-5compat (Maybe for some qt support)
      #qt6-avif-image-plugin (Maybe for some qt support)
      #qt6-base (Maybe for some qt support)
      #qt6-declarative (Maybe for some qt support)
      #qt6-imageformats (Maybe for some qt support)
      #qt6-multimedia (Maybe for some qt support)
      #qt6-positioning (Maybe for some qt support)
      #qt6-quicktimeline (Maybe for some qt support)
      #qt6-sensors (Maybe for some qt support)
      #qt6-svg (Maybe for some qt support)
      #qt6-tools (Maybe for some qt support)
      #qt6-translations (Maybe for some qt support)
      #qt6-virtualkeyboard (Maybe for some qt support)
      #qt6-wayland (Maybe for some qt support)
      kdePackages.syntax-highlighting #syntax-highlighting (Used in Quickshell config)
      upower #upower (Used in Quickshell config)
      wtype #wtype (Used in Hyprland scripts/fuzzel-emoji.sh)
      ydotool #ydotool (Used in Quickshell config)


      ### illogical-impulse-widgets
      fuzzel #fuzzel (Used in Hyprland and Quickshell config; its config is also included)
      glib #glib2 (Provide executable gsettings) (Used in install script, also in matugen and quickshell config)
      imagemagick #imagemagick (Provide executable: magick) (Used in Quickshell config)
      #hypridle (DUPLICATE)
      #hyprutils (DUPLICATE)
      #hyprlock (DUPLICATE)
      #hyprpicker (DUPLICATE)
      #nm-connection-editor (TODOrm: Not needed)
      songrec #songrec (Used in Quickshell config)
      translate-shell #translate-shell (Used in Quickshell config)
      wlogout #wlogout (Used in Hyprland config)

    ]
    ++ [
    (config.lib.nixGL.wrap pkgs.hyprland)
    ];
  }//home_attrs;
}
