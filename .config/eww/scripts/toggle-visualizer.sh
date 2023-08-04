#!/usr/bin/bash
state=$(eww get open_visualizer)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update open_visualizer=false
    sleep 0.15
    eww close visualizer
    eww update cavajson='[]'
else
    cd ~/.config/eww || exit
    eww open visualizer
    eww update open_visualizer=true
fi
