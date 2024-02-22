#!/usr/bin/bash
cd ~/.config/eww || exit

reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')
if [[ "$1" == "--keypress" && "$reserves" == "[0,0,0,50]" ]]; then
    scripts/toggle-winactions.sh
    exit
fi

state=$(eww get rev_dash)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_dash=false
    eww update rev_dash=false
    sleep 0.08
    eww close dashboard 2>/dev/null
else
    scripts/toggle-overview.sh --close &
    scripts/toggle-osettings.sh --close &
    scripts/toggle-onotify.sh --close &
    eww update anim_open_dash=true
    eww open dashboard
    eww update rev_dash=true
fi
