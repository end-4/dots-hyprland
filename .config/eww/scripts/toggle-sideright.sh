#!/usr/bin/bash
state=$(eww get open_sideright)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update open_sideright=false
    sleep 0.2
    eww close sideright
else
    cd ~/.config/eww || exit
    eww open sideright
    eww update open_sideright=true
    eww update open_sideleft=false
    eww close sideleft
    eww update notifications="$(scripts/notifget)"
fi
