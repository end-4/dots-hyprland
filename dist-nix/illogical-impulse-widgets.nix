# Illogical Impulse Widget Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-widgets/PKGBUILD
{ pkgs, ... }:

[
  pkgs.fuzzel
  pkgs.glib
  pkgs.hypridle
  pkgs.hyprutils
  pkgs.hyprlock
  pkgs.hyprpicker
  pkgs.networkmanagerapplet
  # quickshell-git - Not available in stable nixpkgs, may need overlay
  pkgs.translate-shell
  pkgs.wlogout
]
