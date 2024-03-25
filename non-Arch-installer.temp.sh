#!/usr/bin/env bash
#
# This script is for install/update some "packages" which are not installed by system package managers.
# It's function is contained in `install.sh` already, this file is mainly for convenience for non-Arch users.
#
# Though this is not elegant at all. I may improve the method some day in future.
#
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/functions
source ./scriptdata/installers

install-ags
install-Rubik
install-Gabarito
install-OneUI
install-bibata
install-MicroTeX
