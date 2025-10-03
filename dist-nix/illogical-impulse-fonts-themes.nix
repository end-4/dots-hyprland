# Illogical Impulse Fonts and Theming Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-fonts-themes/PKGBUILD
{ pkgs, ... }:

[
  # adw-gtk-theme-git - Not in stable nixpkgs, using alternative
  pkgs.adw-gtk3
  pkgs.breeze-gtk
  # breeze-plus - May not be available in nixpkgs
  # darkly-bin - Not available in nixpkgs
  pkgs.eza
  pkgs.fish
  pkgs.fontconfig
  # kde-material-you-colors - Not available in nixpkgs
  pkgs.kitty
  # matugen-bin - May not be available in stable nixpkgs
  # otf-space-grotesk - Not available in nixpkgs with this name
  pkgs.starship
  # ttf-gabarito-git - Not available in nixpkgs
  pkgs.nerdfonts # Contains jetbrains-mono
  # ttf-material-symbols-variable-git - Not available in stable nixpkgs
  # ttf-readex-pro - Not available in nixpkgs
  # ttf-rubik-vf - Not available in nixpkgs
  pkgs.twemoji-color-font
]
