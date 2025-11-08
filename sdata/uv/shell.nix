{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    pkg-config
    meson
    ninja
    cairo
    dbus
    dbus-glib
    glib
  ];
}
