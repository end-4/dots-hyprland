#!/usr/bin/bash
state=$(eww get rev_ostg)
state_ontf=$(eww get rev_ontf)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update rev_ostg=false
    hyprctl keyword monitor eDP-1,addreserved,53,0,0,0
    # hyprctl keyword decoration:dim_inactive false
    sleep 0.3
    eww close osettings 
    eww update oquery=''
else # state = false
    if [[ "$state_ontf" == "true" ]]; then
        eww update rev_ontf=false
        eww update force_sys_rev=false
    fi
    eww open osettings 
    eww update oquery=''
    hyprctl keyword monitor eDP-1,addreserved,53,0,30,-30
    # hyprctl keyword decoration:dim_inactive true
    eww update rev_ostg=true
    sleep 0.3
    if [[ "$state_ostg" == "true" ]]; then
        eww close onotify 
    fi
fi
