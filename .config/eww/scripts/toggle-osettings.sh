#!/usr/bin/bash
state=$(eww get rev_ostg)
state_ontf=$(eww get rev_ontf)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_ostg=false &
    eww update rev_ostg=false &
    sleep 0.3
    eww close osettings 
    eww update oquery=''
else # state = false
    ~/.config/eww/scripts/toggle-overview.sh --close --nooffset &
    ~/.config/eww/scripts/toggle-onotify.sh --close --nooffset &
    eww update anim_open_ostg=true &
    eww update oquery='' &
    eww open osettings
    eww update rev_ostg=true &
    # Effects
    # ~/.config/eww/scripts/open-blurred.sh
    sleep 0.3
    if [[ "$state_ostg" == "true" ]]; then
        eww close onotify 
    fi
fi
