#!/usr/bin/bash
state=$(eww get rev_ontf)
state_ostg=$(eww get rev_ostg)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update rev_ontf=false
    eww update force_sys_rev=false
    hyprctl keyword monitor eDP-1,addreserved,53,0,0,0
    # hyprctl keyword decoration:dim_inactive false
    sleep 0.3
    eww close onotify 
else
  eww open onotify
    if [[ "$state_ostg" == "true" ]]; then
        eww update rev_ostg=false
    fi
    hyprctl keyword monitor eDP-1,addreserved,53,0,-30,30
    # hyprctl keyword decoration:dim_inactive true
    eww update rev_ontf=true
    eww update force_sys_rev=true
    sleep 0.3
    if [[ "$state_ostg" == "true" ]]; then
        eww close osettings 
        eww update oquery=''
    fi
fi
