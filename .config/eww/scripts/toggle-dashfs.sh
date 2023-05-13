#!/usr/bin/bash
state=$(eww get rev_dashfs)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_dashfs=false
    eww update rev_dashfs=false
    sleep 0.15
    eww close dashfs 
    eww update cavajson=''
else
    eww update anim_open_dashfs=true
    eww open dashfs
    eww update rev_dashfs=true 
fi
