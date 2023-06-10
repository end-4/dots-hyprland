#!/usr/bin/bash
state=$(eww get rev_wingamebar)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww close wingamebar 2>/dev/null
    eww update anim_open_wingamebar=false
    eww update rev_wingamebar=false
else
    eww update anim_open_wingamebar=true
    eww open wingamebar
    eww update rev_wingamebar=true
fi