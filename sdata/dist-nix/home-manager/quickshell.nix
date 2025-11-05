{ pkgs, quickshell, nixGLWrap, ... }:
let
  qs = nixGLWrap quickshell.packages.x86_64-linux.default;
in pkgs.stdenv.mkDerivation {
  name = "illogical-impulse-quickshell-wrapper";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.qt6.wrapQtAppsHook
  ];

  buildInputs = with pkgs; [
    qs
    qt6.qtbase
    kdePackages.qt5compat
    kdePackages.qtdeclarative
    kdePackages.kdialog
    kdePackages.qtwayland
    kdePackages.qtpositioning
    kdePackages.qtlocation
    kdePackages.syntax-highlighting
    gsettings-desktop-schemas
  ];

  installPhase = ''
    mkdir -p $out/bin
    ls -l ${qs}/bin || true
    makeWrapper ${qs}/bin/qs $out/bin/qs \
      --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}
    chmod +x $out/bin/qs
  '';

  meta = with pkgs.lib; {
    description = "Quickshell wrapped with NixGL + bundled Qt deps for home-manager usage";
    license = licenses.mit;
  };
}
