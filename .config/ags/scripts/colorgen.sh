#!/usr/bin/bash

# check if no arguments
if [ $# -eq 0 ]; then
    echo "Usage: colorgen /path/to/image (--apply)"
    exit 1
fi

cd ~/.config/ags/scripts || exit
./material_colors.py --path "$1" > tmp/material_colors.txt

# if --apply is passed, apply the colors
if [ "$2" = "--apply" ]; then
    cp tmp/material_colors.txt ~/.config/ags/scss/_material.scss
    ./applycolor.sh
fi