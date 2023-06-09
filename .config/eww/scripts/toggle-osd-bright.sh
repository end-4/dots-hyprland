#!/usr/bin/bash
cd ~/.config/eww
state=$(eww get osd_vol)

if [[ "$1" == "--open" ]]; then 
    eww update osd_bright=true
elif [[ "$1" == "--close" ]]; then
    eww update osd_bright=false
else
    eww update osd_bright=true
fi
