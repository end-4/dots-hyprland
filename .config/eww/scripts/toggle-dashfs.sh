#!/usr/bin/bash
cd ~/.config/eww || exit

reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')
if [[ "$1" == "--keypress" && "$reserves" == "[0,0,0,50]" ]]; then
    scripts/toggle-winactions.sh
    exit
fi

state=$(eww get rev_dashfs)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_dashfs=false
    eww update rev_dashfs=false
    sleep 0.15
    eww close dashfs 2>/dev/null
    eww update cavajson=''
else
    eww update anim_open_dashfs=true
    eww open dashfs
    eww update rev_dashfs=true 
fi
