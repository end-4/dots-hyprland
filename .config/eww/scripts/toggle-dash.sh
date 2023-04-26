#!/usr/bin/bash
reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')
if [[ "$1" == "--keypress" && "$reserves" == "[0,0,0,50]" ]]; then
    cd ~/.config/eww
    scripts/toggle-winactions.sh
    exit
fi

state=$(eww get rev_dash)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_dash=false
    eww update rev_dash=false
    sleep 0.08
    eww close dashboard
else
    scripts/toggle-overview.sh --close &
    scripts/toggle-osettings.sh --close &
    scripts/toggle-onotify.sh --close &
    eww update anim_open_dash=true
    eww open dashboard
    eww update rev_dash=true
fi
