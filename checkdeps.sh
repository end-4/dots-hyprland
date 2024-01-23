#!/usr/bin/env bash
# Check whether pkgs exist in AUR or repos of Arch.
# This is a workaround for https://github.com/end-4/dots-hyprland/discussions/204
# Do NOT abuse this since it consumes extra bandwidth from AUR server.

cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/functions
source ./scriptdata/installers

pkglistfile=$(mktemp)
pkglistfile_orig=./scriptdata/dependencies.txt
cat $pkglistfile_orig | sed "s_\ _\n_g" > $pkglistfile

echo "The non-existent pkgs in $pkglistfile_orig are listed as follows."
# Borrowed from https://bbs.archlinux.org/viewtopic.php?pid=1490795#p1490795
comm -23 <(sort -u $pkglistfile) <(sort -u <(wget -q -O - https://aur.archlinux.org/packages.gz | gunzip) <(pacman -Ssq))
echo "End. If nothing appears, then all pkgs exist."
rm $pkglistfile
