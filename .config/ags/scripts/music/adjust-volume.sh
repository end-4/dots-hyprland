#!/bin/bash

change=$1

players=$(playerctl -l)

for player in $players; do
    if playerctl -p "$player" volume &>/dev/null; then
        current_volume=$(playerctl -p "$player" volume)

        new_volume=$(echo "$current_volume + $change" | bc)
        
        if (( $(echo "$new_volume > 1.0" | bc -l) )); then
            new_volume=1.0
        elif (( $(echo "$new_volume < 0.0" | bc -l) )); then
            new_volume=0.0
        fi

        playerctl -p "$player" volume "$new_volume"
        exit 0
    fi
done

exit 1
