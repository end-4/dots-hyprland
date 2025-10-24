# Fonts and themes packages
{ pkgs, breeze-plus, matugen, gabarito }:

let
  # Custom package derivations
  # based on AUR analogs
  breeze-plus-pkg = pkgs.stdenv.mkDerivation {
    pname = "breeze-plus";
    version = "6.2.5";
    src = breeze-plus;

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/share/icons
      cp -r src/breeze-plus* $out/share/icons/
    '';
  };

  gabarito-pkg = pkgs.stdenv.mkDerivation {
    pname = "gabarito";
    version = "1.0.0";
    src = gabarito;

    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      mkdir -p $out/share/licenses/gabarito
      cp fonts/ttf/*.ttf $out/share/fonts/truetype/
      cp OFL.txt $out/share/licenses/gabarito/
    '';
  };

in
{
  # Fonts and themes
  adw-gtk3 = pkgs.adw-gtk3;
  breeze-icons = pkgs.kdePackages.breeze-icons;
  breeze-plus = breeze-plus-pkg;
  darkly = pkgs.darkly;
  darkly-qt5 = pkgs.darkly-qt5;
  eza = pkgs.eza;
  fish = pkgs.fish;
  fontconfig = pkgs.fontconfig;
  kitty = pkgs.kitty;
  matugen = matugen.packages.${pkgs.system}.default;
  #space-grotesk = pkgs.space-grotesk;
  starship = pkgs.starship;
  gabarito = gabarito-pkg;
  jetbrains-mono-nerd = pkgs.nerd-fonts.jetbrains-mono;
  material-symbols = pkgs.material-symbols;
  #readex-pro = pkgs.readex-pro;
  rubik = pkgs.rubik;
  twemoji-color-font = pkgs.twemoji-color-font;
}
