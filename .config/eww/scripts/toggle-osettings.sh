#!/usr/bin/bash
reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')
if [[ "$1" == "--keypress" && "$reserves" == "[0,0,0,50]" ]]; then
    cd ~/.config/eww
    scripts/toggle-winnews.sh
    exit
fi


state=$(eww get rev_ostg)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_ostg=false
    eww update rev_ostg=false
    sleep 0.15
    eww close osettings 
    eww update oquery=''
else # state = false
    eww update anim_open_ostg=true
    eww update oquery='' &
    eww open osettings
    eww update rev_ostg=true &
fi
