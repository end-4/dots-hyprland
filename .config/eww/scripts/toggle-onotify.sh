#!/usr/bin/bash
state=$(eww get rev_ontf)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_ontf=false
    eww update rev_ontf=false
    eww update force_sys_rev=false
    sleep 0.15
    eww close onotify 
else
    eww update anim_open_ontf=true
    eww open onotify
    eww update rev_ontf=true &
    eww update force_sys_rev=true &
fi
