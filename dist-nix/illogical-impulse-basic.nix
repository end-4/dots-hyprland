# Illogical Impulse Basic Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-basic/PKGBUILD
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.basic.enable = mkEnableOption "Illogical Impulse basic dependencies";

  config = mkIf config.illogical-impulse.basic.enable {
    home.packages = [
      pkgs.axel
      pkgs.bc
      pkgs.coreutils
      pkgs.cliphist
      pkgs.cmake
      pkgs.curl
      pkgs.rsync
      pkgs.wget
      pkgs.ripgrep
      pkgs.jq
      pkgs.meson
      pkgs.xdg-user-dirs
    ];
  };
}
