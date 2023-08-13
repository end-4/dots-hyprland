#!/usr/bin/bash
cd ~/.config/eww || exit
mkdir -p ~/.config/eww/scripts/cache/

state=$(eww get open_powerview)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    hyprctl dispatch submap reset
    eww close powerview 2>/dev/null &
    eww update overview_query='' &
    eww update open_powerview=false &
else
    scripts/allapps > scripts/cache/entries.txt &
    scripts/allappnames > scripts/cache/entrynames.txt &
    eww update overview_query=''  &
    eww update overview_hover_name='{"class":"LMB: Focus | MMB: Close | RMB: Select/Move","title":"Powerview","workspace":{"id":0,"name":"0"},"icon": "/usr/share/icons/breeze-dark/actions/16/window.svg", "size": [0,0], "at": [0,0]}' &
    eww open powerview
    eww update open_powerview=true
    hyprctl dispatch submap powerview
fi
