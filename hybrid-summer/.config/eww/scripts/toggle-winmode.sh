#!/usr/bin/bash
reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')

if [[ "$reserves" == "[0,61,0,0]" ]]; then
    eww open winbar &
    eww close bar &
    hyprctl keyword monitor eDP-1,addreserved,0,50,0,0

    hyprctl keyword decoration:rounding 0 
    hyprctl keyword general:gaps_in 0 
    hyprctl keyword general:gaps_out 0
    hyprctl keyword general:border_size 0
    hyprctl keyword windowrulev2 'rounding 15, floating:1'
    hyprctl keyword decoration:drop_shadow true
else
    eww close winbar &
    eww open bar &
    hyprctl keyword monitor eDP-1,addreserved,61,0,0,0

    hyprctl keyword decoration:rounding 17 
    hyprctl keyword general:gaps_in 4 
    hyprctl keyword general:gaps_out 8
    hyprctl keyword general:border_size 2
    hyprctl keyword windowrulev2 'unset, floating:1'
    hyprctl keyword decoration:drop_shadow false
fi
