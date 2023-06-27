#!/usr/bin/bash
state=$(eww get open_sideright)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update open_sideright=false
    eww update bar_offset=0
else
    cd ~/.config/eww || exit
    eww open sideright
    eww update open_sideright=true
    eww update bar_offset=-1
    eww update open_sideleft=false
    eww update notifications="$(scripts/notifget)"
fi
