#!/bin/bash

state=$(hyprctl getoption decoration:rounding -j | gojq '.int')

if [[ "$state" != "0" || "$1" == "--enable" ]]; then
    eww update compact=true &
    hyprctl keyword decoration:rounding 0 
    hyprctl keyword general:gaps_in 0 
    hyprctl keyword general:gaps_out 0
    hyprctl keyword monitor eDP-1,addreserved,69,0,0,0  
    if [[ "$2" == "--border" ]]; then
        hyprctl keyword general:border_size "$3"
    else
        hyprctl keyword general:border_size 1
    fi
else
    eww update compact=false &
    hyprctl reload
fi