#!/usr/bin/bash
state=$(eww get rev_winlang)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_winlang=false
    eww update rev_winlang=false
    sleep 0.1
    eww close winlang
else
    eww update anim_open_winlang=true
    eww open winlang
    eww update rev_winlang=true
fi
