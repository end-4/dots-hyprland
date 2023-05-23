#!/usr/bin/bash
cd ~/.config/eww

state=$(eww get rev_wintaskview)

if [[ "$state" == "true" || "$1" == "--close" ]]; then 
    eww update anim_open_wintaskview=false
    eww update rev_wintaskview=false
    sleep 0.1
    eww close wintaskview
else
    eww update anim_open_wintaskview=true
    eww open wintaskview
    eww update rev_wintaskview=true
fi
