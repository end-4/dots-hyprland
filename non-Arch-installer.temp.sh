#!/usr/bin/env bash
#
# This script is for installing/updating some "packages" which are not installed by system package managers.
# Its functions are contained in `install.sh` already, and this just makes it more convenient for non-Arch users.
#
# Though this is not elegant at all. I may improve the method some day in the future.
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
