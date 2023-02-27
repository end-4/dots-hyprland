#!/usr/bin/bash
state=$(eww get music_open)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update music_open=false
    eww close music
else
    eww open music
    # hyprctl keyword decoration:dim_inactive true
    eww update music_open=true
fi
