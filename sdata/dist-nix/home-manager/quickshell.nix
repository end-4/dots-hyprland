{ pkgs, quickshell, 
#nixGLWrap,
... }:
let
  #qs = nixGLWrap quickshell.packages.x86_64-linux.default;
  qs = quickshell.packages.x86_64-linux.default;
in pkgs.stdenv.mkDerivation {
  name = "illogical-impulse-quickshell-wrapper";
  meta = with pkgs.lib; {
    #description = "Quickshell wrapped with NixGL + bundled Qt deps for home-manager usage";
    description = "Quickshell bundled Qt deps for home-manager usage";
    license = licenses.gpl3Only;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.qt6.wrapQtAppsHook
  ];

  buildInputs = with pkgs; [
    qs
    kdePackages.qtwayland
    kdePackages.qtpositioning
    kdePackages.qtlocation
    kdePackages.syntax-highlighting
    gsettings-desktop-schemas
    # https://nixos.wiki/wiki/Qt
    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/libraries/qt-6/srcs.nix
    qt6.qtbase #qt6-base
    qt6.qtdeclarative #qt6-declarative
    qt6.qt5compat #qt6-5compat
    #qt6-avif-image-plugin (TODO: seems not available as nixpkg)
    qt6.qtimageformats #qt6-imageformats
    qt6.qtmultimedia #qt6-multimedia
    qt6.qtpositioning #qt6-positioning
    qt6.qtquicktimeline #qt6-quicktimeline
    qt6.qtsensors #qt6-sensors
    qt6.qtsvg #qt6-svg
    qt6.qttools #qt6-tools
    qt6.qttranslations #qt6-translations
    qt6.qtvirtualkeyboard #qt6-virtualkeyboard
    qt6.qtwayland #qt6-wayland
    kdePackages.kirigami #kirigami
    kdePackages.kdialog #kdialog
    kdePackages.syntax-highlighting #syntax-highlighting
  ];

  installPhase = ''
    mkdir -p $out/bin
    ls -l ${qs}/bin || true
    makeWrapper ${qs}/bin/qs $out/bin/qs \
      --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}
    chmod +x $out/bin/qs
  '';
}
