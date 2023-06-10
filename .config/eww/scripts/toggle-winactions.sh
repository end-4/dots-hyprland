#!/usr/bin/bash
state=$(eww get rev_winactions)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    if [[ "$2" == "settings" ]]; then
        gnome-control-center &
    fi
    if [[ "$2" == "power" ]]; then
        gnome-control-center power &
    fi
    eww update anim_open_winactions=false
    eww update rev_winactions=false
    sleep 0.1
    eww close winactions 2>/dev/null
else
    eww update anim_open_winactions=true
    eww open winactions
    eww update rev_winactions=true
fi
