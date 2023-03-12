#!/usr/bin/bash
state=$(eww get open_overview)

cd ~/.config/eww

if [[ "$state" == "true" || "$1" == "--close" ]]; then 
    eww close overview
    eww update overview_query='' 
    eww update open_overview=false
else
    scripts/toggle-osettings.sh --close &
    scripts/toggle-onotify.sh --close &
    scripts/toggle-dash.sh --close &
    scripts/listentrynames.py &
    scripts/listentries.py &
    eww update overview_query=''  &
    eww update overview_hover_name='{"class":"LMB: Focus | MMB: Close | RMB: Select/Move","title":"Activities Overview","workspace":{"id":5,"name":"5"},"icon": "/usr/share/icons/breeze-dark/actions/16/window.svg"}' &
    eww open overview
    eww update open_overview=true
fi
