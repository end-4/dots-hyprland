#!/usr/bin/bash

if [[ "$2" == "" ]]; then # basic rice switching
    notify-send 'Usage: >swr [save name] [load name]'
    exit
fi
mkdir -p ~/.config/__enderice/
mv ~/.config/eww ~/.config/__enderice/eww_"$1"
mv ~/.config/hypr ~/.config/__enderice/hypr_"$1"

mv ~/.config/__enderice/eww_"$2" ~/.config/eww
mv ~/.config/__enderice/hypr_"$2" ~/.config/hypr

pkill eww && eww open bar && eww open bgdecor