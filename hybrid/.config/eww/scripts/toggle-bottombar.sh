#!/usr/bin/bash
state=$(eww get rev_bottombar)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_bottombar=false
    eww update rev_bottombar=false
    # eww update force_sys_rev=false
    sleep 0.15
    eww close bottombar 2>/dev/null
    eww close bottombar-back 2>/dev/null
    eww update cavajson=''
else
    eww update anim_open_bottombar=true
    eww open bottombar-back
    eww open bottombar
    eww update rev_bottombar=true
    # eww update force_sys_rev=true &
fi
