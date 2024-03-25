#!/usr/bin/env bash
#
# This script is for install/update the "packages" w/o system package managers.
# Convenient for non-Arch users.
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
