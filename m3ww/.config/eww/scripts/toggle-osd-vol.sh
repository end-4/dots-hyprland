#!/usr/bin/bash
cd ~/.config/eww
state=$(eww get osd_bright)

if [[ "$1" == "--open" ]]; then 
    eww update osd_vol=true
elif [[ "$1" == "--close" ]]; then
    eww update osd_vol=false
else
    eww update osd_vol=true
fi