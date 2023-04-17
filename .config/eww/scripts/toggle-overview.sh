#!/usr/bin/bash
reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')
if [[ "$1" == "--super" && "$reserves" == "[0,0,0,50]" ]]; then
    cd ~/.config/eww
    scripts/toggle-winstart.sh
    exit
fi

state=$(eww get open_overview)

cd ~/.config/eww || exit

if [[ "$state" == "true" || "$1" == "--close" ]]; then 
    eww close overview &
    eww update overview_query='' &
    eww update open_overview=false &
else
    # Python
    # scripts/listentrynames.py &
    # scripts/listentries.py &
    scripts/allappnames > scripts/cache/entrynames.txt &
    scripts/allapps > scripts/cache/entries.txt &
    eww update overview_query=''  &
    eww update overview_hover_name='{"class":"LMB: Focus | MMB: Close | RMB: Select/Move","title":"Activities Overview","workspace":{"id":5,"name":"5"},"icon": "/usr/share/icons/breeze-dark/actions/16/window.svg"}' &
    eww open overview
    eww update open_overview=true
fi
