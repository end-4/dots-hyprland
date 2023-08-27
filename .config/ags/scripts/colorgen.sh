#!/usr/bin/bash

# check if no arguments
if [ $# -eq 0 ]; then
    echo "Usage: colorgen /path/to/image (--apply)"
    exit 1
fi

# check if the file ~/.cache/ags/user/colormode.txt exists. if not, create it. else, read it to $lightdark
lightdark=""
if [ ! -f ~/.cache/ags/user/colormode.txt ]; then
    echo "" > ~/.cache/ags/user/colormode.txt
else 
    lightdark=$(cat ~/.cache/ags/user/colormode.txt) # either "" or "-l"
fi

cd ~/.config/ags/scripts || exit
./material_colors.py --path "$1" "$lightdark" > tmp/material_colors.txt

# if --apply is passed, apply the colors
if [ "$2" = "--apply" ]; then
    cp tmp/material_colors.txt ~/.config/ags/scss/_material.scss
    ./applycolor.sh
fi