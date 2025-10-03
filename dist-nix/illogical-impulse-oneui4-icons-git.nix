# Illogical Impulse OneUI4 Icons (Optional)
# These packages are equivalent to dist-arch/illogical-impulse-oneui4-icons-git/PKGBUILD
# Note: This is currently commented out in dist-arch/install-deps.sh
{ config, lib, pkgs, ... }:

with lib;

{
  options.illogical-impulse.oneui4-icons.enable = mkEnableOption "Illogical Impulse OneUI4 icons (optional)";

  config = mkIf config.illogical-impulse.oneui4-icons.enable {
    home.packages = [
      # oneui4-icons - Not available in stable nixpkgs
      # This package is a custom icon theme from https://github.com/end-4/OneUI4-Icons
      # May need to be installed manually or through an overlay
    ];
  };
}
