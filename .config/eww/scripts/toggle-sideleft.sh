#!/usr/bin/bash
state=$(eww get open_sideleft)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update open_sideleft=false
    eww update bar_offset=0
else
    eww open sideleft
    eww update open_sideleft=true
    eww update bar_offset=1
    eww update open_sideright=false
fi
