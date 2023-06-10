#!/usr/bin/bash
reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')

if [[ "$reserves" == "[0,61,0,0]" ]]; then
    eww close bottomline 2>/dev/null
    eww open winbar
    eww close bar 2>/dev/null
    hyprctl keyword monitor eDP-1,addreserved,0,50,0,0

    hyprctl keyword decoration:rounding 8
    hyprctl keyword general:border_size 1
    hyprctl keyword decoration:drop_shadow true

    hyprctl keyword general:col.active_border 'rgba(494949dd)'
    hyprctl keyword general:col.inactive_border 'rgba(494949aa)'
else
    eww close winbar 2>/dev/null
    eww open bar
    eww open bottomline
    hyprctl keyword monitor eDP-1,addreserved,61,0,0,0

    hyprctl reload
fi
