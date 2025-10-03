# Illogical Impulse MicroTeX Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-microtex-git/PKGBUILD
# Note: MicroTeX itself may need to be built from source or added as an overlay
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.microtex.enable = mkEnableOption "Illogical Impulse MicroTeX dependencies";

  config = mkIf config.illogical-impulse.microtex.enable {
    home.packages = [
      pkgs.tinyxml-2
      pkgs.gtkmm3
      pkgs.gtksourceviewmm4
      pkgs.cairomm
      pkgs.git
      pkgs.cmake
    ];
  };
}
