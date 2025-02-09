#!/bin/bash

change=$1

current_volume=$(playerctl volume)

new_volume=$(echo "$current_volume + $change" | bc)

if (( $(echo "$new_volume > 1.0" | bc -l) )); then
  new_volume=1.0
elif (( $(echo "$new_volume < 0.0" | bc -l) )); then
  new_volume=0.0
fi

playerctl volume "$new_volume"
