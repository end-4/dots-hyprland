#!/usr/bin/bash
state=$(eww get rev_ostg)
state_ontf=$(eww get rev_ontf)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_ostg=false &
    eww update rev_ostg=false &
    sleep 0.15
    eww close osettings 
    eww update oquery=''
else # state = false
    eww update anim_open_ostg=true &
    eww update oquery='' &
    eww open osettings
    eww update rev_ostg=true &
fi
