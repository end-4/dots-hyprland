# Illogical Impulse Screenshot and Recording Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-screencapture/PKGBUILD
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.screencapture.enable = mkEnableOption "Illogical Impulse screenshot and recording dependencies";

  config = mkIf config.illogical-impulse.screencapture.enable {
    home.packages = [
      pkgs.hyprshot
      pkgs.slurp
      pkgs.swappy
      pkgs.tesseract
      pkgs.tesseract.languages.eng
      pkgs.wf-recorder
    ];
  };
}
