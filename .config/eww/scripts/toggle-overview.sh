#!/usr/bin/bash
cd ~/.config/eww || exit
mkdir -p ~/.config/eww/scripts/cache/

reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')
if [[ "$reserves" == "[0,0,0,50]" ]]; then
    if [[ "$1" == "--keypress" ]]; then
        scripts/toggle-winstart.sh
        exit
    elif [[ "$1" == "--overview" && "$reserves" == "[0,0,0,50]" ]]; then
        scripts/toggle-wintaskview.sh
        exit
    fi
fi

state=$(eww get open_overview)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww close overview 2>/dev/null &
    eww update overview_query='' &
    eww update open_overview=false &
else
    scripts/allapps > scripts/cache/entries.txt &
    scripts/allappnames > scripts/cache/entrynames.txt &
    eww update overview_query=''  &
    eww update overview_hover_name='{"class":"LMB: Focus | MMB: Close | RMB: Select/Move","title":"Activities Overview","workspace":{"id":5,"name":"5"},"icon": "/usr/share/icons/breeze-dark/actions/16/window.svg"}' &
    eww open overview
    eww update open_overview=true
fi
