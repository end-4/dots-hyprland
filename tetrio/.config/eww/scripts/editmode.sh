#!/usr/bin/bash
if [ "$1" == "enable" ]; then
    hyprctl keyword bindm ,mouse:273,resizewindow
    hyprctl keyword bindm ,mouse:274,movewindow
    hyprctl keyword bind ,mouse_up,workspace,+1
    hyprctl keyword bind ,mouse_down,workspace,-1
    eww update editing=true
elif [ "$1" == "disable" ]; then 
    hyprctl keyword unbind ,mouse:273
    hyprctl keyword unbind ,mouse:274
    hyprctl keyword unbind ,mouse_up
    hyprctl keyword unbind ,mouse_down
    eww update editing=false
fi