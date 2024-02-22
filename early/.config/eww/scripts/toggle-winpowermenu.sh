#!/usr/bin/bash
state=$(eww get rev_winpowermenu)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_winpowermenu=false
    eww update rev_winpowermenu=false
    eww update winsearch='' &
    sleep 0.15
    eww close winpowermenu 2>/dev/null
else
    eww update anim_open_winpowermenu=true
    eww open winpowermenu
    eww update rev_winpowermenu=true
fi
