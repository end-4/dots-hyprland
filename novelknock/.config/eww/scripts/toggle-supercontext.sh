#!/usr/bin/bash
state=$(eww get open_supercontext)

if [[ "$state" -gt "0" || "$1" == "--close" ]]; then
    eww update open_supercontext=0
    sleep 0.1
    eww close supercontext 2>/dev/null
else
    eww update supercontext_pos_x="$(hyprctl cursorpos -j | gojq '.x')"
    eww update supercontext_pos_y="$(hyprctl cursorpos -j | gojq '.y')" &
    eww open supercontext
    eww update ws_to_swap=0
    eww update ws_to_dump=0
    eww update open_supercontext=1
    eww update open_supercontext=2
    eww update open_supercontext=3
    eww update open_supercontext=4
    eww update open_supercontext=5
fi