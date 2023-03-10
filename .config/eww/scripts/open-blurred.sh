#!/usr/bin/bash

current_addresses=("$(hyprctl layers -j | jq -r '.[] | .levels | ."2" | .[] | select(.namespace == "gtk-layer-shell") | .address')")
for current_address in ${current_addresses[@]}; do
  if [[ ! "${all_address[*]}" =~ ${current_address} ]]; then
    all_address+=($current_address)
    hyprctl keyword blurls "address::$current_address"
  fi
done