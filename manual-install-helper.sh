#!/usr/bin/env bash
#
# This script is for installing/updating some "packages" for non-Arch users.
#

cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/functions
source ./scriptdata/installers

if command -v pacman >/dev/null 2>&1;then printf "\e[31m[$0]: pacman found, it seems that the system is ArchLinux or Arch-based distro. Aborting...\e[0m\n";exit 1;fi
install-ags
install-Rubik
install-Gabarito
install-OneUI
install-bibata
install-MicroTeX
