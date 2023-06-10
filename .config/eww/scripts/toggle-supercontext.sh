#!/usr/bin/bash
state=$(eww get rev_supercontext)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_supercontext=false
    eww update rev_supercontext=false
    sleep 0.1
    eww close supercontext 2>/dev/null
else
    eww update supercontext_pos_x="$(hyprctl cursorpos -j | gojq '.x')"
    eww update supercontext_pos_y="$(hyprctl cursorpos -j | gojq '.y')" &
    eww update anim_open_supercontext=true &
    eww open supercontext
    eww update rev_supercontext=true
    eww update ws_to_swap=0
fi