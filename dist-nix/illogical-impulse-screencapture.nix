# Illogical Impulse Screenshot and Recording Dependencies
# These packages are equivalent to dist-arch/illogical-impulse-screencapture/PKGBUILD
{ pkgs, ... }:

[
  pkgs.hyprshot
  pkgs.slurp
  pkgs.swappy
  pkgs.tesseract
  pkgs.tesseract.languages.eng
  pkgs.wf-recorder
]
