# quickshell-git derivation using quickshell's own Nix files
{ pkgs, lib, quickshell-src }:

let
  quickshell-pkg = import "${quickshell-src}/default.nix" {
    inherit lib pkgs;
    nix-gitignore = pkgs.nix-gitignore;
    stdenv = pkgs.stdenv;
    keepDebugInfo = false;

    pkg-config = pkgs.pkg-config;
    cmake = pkgs.cmake;
    ninja = pkgs.ninja;
    spirv-tools = pkgs.spirv-tools;
    qt6 = pkgs.qt6;
    breakpad = pkgs.breakpad;
    jemalloc = pkgs.jemalloc;
    cli11 = pkgs.cli11;
    wayland = pkgs.wayland;
    wayland-protocols = pkgs.wayland-protocols;
    wayland-scanner = pkgs.wayland-scanner;
    xorg = pkgs.xorg;
    libdrm = pkgs.libdrm;
    libgbm = pkgs.libgbm;
    pipewire = pkgs.pipewire;
    pam = pkgs.pam;

    # Set gitRev to a fixed value since we're using a specific commit
    #gitRev = "3e2ce40b18af943f9ba370ed73565e9f487663ef";

    # Configure build options
    debug = true;
    withCrashReporter = true;
    withJemalloc = true;
    withQtSvg = true;
    withWayland = true;
    withX11 = true;
    withPipewire = true;
    withPam = true;
    withHyprland = true;
    withI3 = true;
  };
in
{
  quickshell = quickshell-pkg;
}
