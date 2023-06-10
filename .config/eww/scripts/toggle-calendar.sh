#!/usr/bin/bash
state=$(eww get rev_calendar)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_calendar=false
    eww update rev_calendar=false
    sleep 0.15
    eww close calendar 2>/dev/null
else
    eww update anim_open_calendar=true
    eww open calendar
    eww update rev_calendar=true
fi
