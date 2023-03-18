#!/usr/bin/bash

exit 0 # BLURS ARE FUCKING UNSTABLE AAAAAAA

current_addresses=("$(hyprctl layers -j | jq -r '.[] | .levels | ."2" | .[] | select(.namespace == "gtk-layer-shell") | .address')")
for current_address in ${current_addresses[@]}; do
      hyprctl keyword layerrule "blur,address:$current_address"
      hyprctl keyword layerrule "ignorezero,address:$current_address"
done
