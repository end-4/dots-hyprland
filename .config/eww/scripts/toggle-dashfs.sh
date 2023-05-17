#!/usr/bin/bash
reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')
if [[ "$1" == "--keypress" && "$reserves" == "[0,0,0,50]" ]]; then
    cd ~/.config/eww
    scripts/toggle-winactions.sh
    exit
fi

state=$(eww get rev_dashfs)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_dashfs=false
    eww update rev_dashfs=false
    sleep 0.15
    eww close dashfs 
    eww update cavajson=''
else
    eww update anim_open_dashfs=true
    eww open dashfs
    eww update rev_dashfs=true 
fi
