# Python development and GTK dependencies
{ pkgs }:

{
  # Python development tools
  clang = pkgs.clang;
  uv = pkgs.uv;

  # GTK4 and GUI development
  gtk4 = pkgs.gtk4;
  libadwaita = pkgs.libadwaita;
  libsoup_3 = pkgs.libsoup_3;
  libportal-gtk4 = pkgs.libportal-gtk4;
  gobject-introspection = pkgs.gobject-introspection;
  sassc = pkgs.sassc;
}
