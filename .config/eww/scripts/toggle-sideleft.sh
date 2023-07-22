#!/usr/bin/bash
state=$(eww get open_sideleft)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update open_sideleft=false
else
    cd ~/.config/eww || exit
    eww open sideleft
    eww update open_sideleft=true
    eww update open_sideright=false
fi
