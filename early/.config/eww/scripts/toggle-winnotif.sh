#!/usr/bin/bash
state=$(eww get rev_winnotif)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_winnotif=false
    eww update rev_winnotif=false
    sleep 0.2
    eww close winnotif 2>/dev/null
else
    eww update anim_open_winnotif=true
    eww open winnotif
    eww update rev_winnotif=true
fi
