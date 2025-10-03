# Illogical Impulse MicroTeX Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-microtex-git/PKGBUILD
# Note: MicroTeX itself may need to be built from source or added as an overlay
{ pkgs, ... }:

[
  pkgs.tinyxml-2
  pkgs.gtkmm3
  pkgs.gtksourceviewmm4
  pkgs.cairomm
  pkgs.git
  pkgs.cmake
]
