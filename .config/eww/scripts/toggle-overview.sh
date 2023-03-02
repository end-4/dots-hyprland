#!/usr/bin/bash
state=$(eww get open_overview)

cd ~/.config/eww

if [[ "$state" == "false" ]]; then 
    scripts/toggle-osettings.sh --close &
    scripts/toggle-onotify.sh --close &
    scripts/listentrynames.py &
    scripts/listentries.py &
    eww update overview_query=''  &
    eww update overview_hover_name="Activities Overview" &
    eww open overview
    eww update open_overview=true
else
    eww close overview
    eww update overview_query='' 
    eww update open_overview=false
fi
