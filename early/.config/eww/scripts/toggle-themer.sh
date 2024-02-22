#!/usr/bin/bash
state=$(eww get rev_themer)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_themer=false
    eww update rev_themer=false
    sleep 0.25
    eww close themer 2>/dev/null
else
    eww update anim_open_themer=true
    eww open themer
    eww update rev_themer=true
fi
