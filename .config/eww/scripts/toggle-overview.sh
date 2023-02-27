#!/usr/bin/bash
state=$(~/.config/eww/scripts/isopen.sh overview)

cd ~/.config/eww

if [[ "$state" == "false" ]]; then 
    scripts/listentrynames.py &
    scripts/listentries.py &
    eww update anim_open_search=true
    eww update overview_query='' 
    eww update overview_hover_name="Activities Overview"
    eww open --toggle overview 
else
    eww open --toggle overview 
    eww update overview_query='' 
fi
