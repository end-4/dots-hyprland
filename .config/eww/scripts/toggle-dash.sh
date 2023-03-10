#!/usr/bin/bash
state=$(eww get rev_dash)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_dash=false
    eww update rev_dash=false
    # sleep 0.25
    eww close dashboard
else
    eww update anim_open_dash=true
    eww open dashboard
    # hyprctl keyword decoration:dim_inactive true
    eww update rev_dash=true
fi
