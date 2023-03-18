#!/usr/bin/bash
state=$(eww get rev_ontf)
state_ostg=$(eww get rev_ostg)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_ontf=false
    eww update rev_ontf=false
    eww update force_sys_rev=false
    sleep 0.3
    eww close onotify 
else
    ~/.config/eww/scripts/toggle-overview.sh --close --nooffset &
    ~/.config/eww/scripts/toggle-osettings.sh --close --nooffset &
    eww update anim_open_ontf=true
    eww open onotify
    eww update rev_ontf=true &
    eww update force_sys_rev=true &
    # Effects
    # ~/.config/eww/scripts/open-blurred.sh
    sleep 0.3
    if [[ "$state_ostg" == "true" ]]; then
        eww close osettings 
        eww update oquery=''
    fi
fi
