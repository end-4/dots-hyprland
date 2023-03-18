#!/bin/bash

state=$(hyprctl getoption decoration:rounding -j | gojq '.int')

if [[ "$state" != "0" || "$1" == "--enable" ]]; then
    hyprctl keyword decoration:rounding 0 
    hyprctl keyword general:gaps_in 0 
    hyprctl keyword general:gaps_out 0
    if [[ "$2" == "--border" ]]; then
        hyprctl keyword general:border_size "$3"
    else
        hyprctl keyword general:border_size 1
    fi
else
    hyprctl reload
fi