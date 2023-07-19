#!/usr/bin/bash
BAR_HEIGHT_NORMAL='40'
BAR_HEIGHT_NORMAL_BOTTOM='60'
bar_height=$(eww get BAR_HEIGHT)

if [ "$1" == "bottom" ] || [ "$bar_height" == "$BAR_HEIGHT_NORMAL" ]; then
    eww close bar
    eww update BAR_HEIGHT=0
    eww update BAR_HEIGHT_BOTTOM=$BAR_HEIGHT_NORMAL_BOTTOM
    eww open barbottom
    hyprctl keyword monitor ,addreserved,0,$BAR_HEIGHT_NORMAL_BOTTOM,0,0
else
    eww close barbottom
    eww update BAR_HEIGHT=$BAR_HEIGHT_NORMAL
    eww update BAR_HEIGHT_BOTTOM=0
    eww open bar
    hyprctl keyword monitor ,addreserved,$BAR_HEIGHT_NORMAL,0,0,0
fi