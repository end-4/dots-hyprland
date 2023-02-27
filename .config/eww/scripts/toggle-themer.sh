#!/usr/bin/bash
state=$(eww get rev_themer)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_themer=false
    eww update rev_themer=false
    sleep 0.3
    eww close themer
else
    eww update anim_open_themer=true
    eww open themer
    # hyprctl keyword decoration:dim_inactive true
    eww update rev_themer=true
fi
