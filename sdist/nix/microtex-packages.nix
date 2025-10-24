# MicroTeX derivation
{ pkgs, microtex-src }:

let
  microtex-pkg = pkgs.stdenv.mkDerivation rec {
    pname = "illogical-impulse-microtex";
    version = "r494.0e3707f";

    src = microtex-src;

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
    ];

    buildInputs = with pkgs; [
      tinyxml-2
      gtkmm3
      gtksourceviewmm4
      cairomm
    ];

    preConfigure = ''
      sed -i 's/gtksourceviewmm-3.0/gtksourceviewmm-4.0/' CMakeLists.txt
      sed -i 's/tinyxml2.so.10/tinyxml2.so.11/' CMakeLists.txt
    '';

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=None"
    ];

    installPhase = ''
      mkdir -p $out/opt/MicroTeX
      install -Dm0755 build/LaTeX -t $out/opt/MicroTeX/
      cp -r build/res $out/opt/MicroTeX/
      install -Dm0644 LICENSE -t $out/share/licenses/$pname/
    
      # Create a wrapper script
      mkdir -p $out/bin
      cat > $out/bin/microtex << EOF
      #!/bin/sh
      exec $out/opt/MicroTeX/LaTeX "\$@"
      EOF
      chmod +x $out/bin/microtex
    '';

    meta = with pkgs.lib; {
      description = "MicroTeX for illogical-impulse dotfiles. A dynamic, cross-platform, and embeddable LaTeX rendering library";
      homepage = "https://github.com/NanoMichael/MicroTeX";
      license = licenses.mit;
      maintainers = with maintainers; [ ];
      platforms = platforms.linux;
    };
  };
in
{
  microtex = microtex-pkg;
}
