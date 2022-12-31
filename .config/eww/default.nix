{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: let
  dependencies = with pkgs; [
    config.wayland.windowManager.hyprland.package
    config.programs.eww.package
    bash
    bc
    blueberry
    bluez
    coreutils
    dbus
    dunst
    findutils
    gawk
    gnused
    gojq
    iwgtk
    jaq
    light
    networkmanager
    networkmanagerapplet
    pavucontrol
    playerctl
    procps
    pulseaudio
    ripgrep
    socat
    udev
    upower
    util-linux
    wget
    wireplumber
    wlogout
    wofi
  ];
in {
  programs.eww = {
    enable = true;
    package = inputs.eww.packages.${pkgs.system}.eww-wayland;
    # remove nix files
    configDir = lib.cleanSourceWith {
      filter = name: _type: let
        baseName = baseNameOf (toString name);
      in
        !(lib.hasSuffix ".nix" baseName);
      src = lib.cleanSource ./.;
    };
  };

  systemd.user.services.eww = {
    Unit = {
      Description = "Eww Daemon";
      # not yet implemented
      # PartOf = ["tray.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath dependencies}";
      ExecStart = "${config.programs.eww.package}/bin/eww daemon --no-daemonize";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
