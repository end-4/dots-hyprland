# Illogical Impulse Bibata Modern Classic Cursor Theme
# These packages are equivalent to dist-arch/illogical-impulse-bibata-modern-classic-bin/PKGBUILD
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.bibata-cursors.enable = mkEnableOption "Illogical Impulse Bibata cursor theme";

  config = mkIf config.illogical-impulse.bibata-cursors.enable {
    home.packages = [
      pkgs.bibata-cursors
    ];
  };
}
