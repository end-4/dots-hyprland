#!/usr/bin/bash
state=$(eww get rev_winnews)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_winnews=false
    eww update rev_winnews=false
    sleep 0.15
    eww close winnews 2>/dev/null
    eww update oquery=''
else
    eww update anim_open_winnews=true
    eww update oquery='' &
    eww open winnews
    eww update rev_winnews=true
fi
