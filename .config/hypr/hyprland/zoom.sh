#!/usr/bin/env bash

# Controls Hyprland's cursor zoom_factor, clamped between 1.0 and 3.0

# Get current zoom level
get_zoom() {
    hyprctl getoption -j cursor:zoom_factor | jq '.float'
}

# Clamp a value between 1.0 and 3.0
clamp() {
    local val="$1"
    awk "BEGIN {
        v = $val;
        if (v < 1.0) v = 1.0;
        if (v > 3.0) v = 3.0;
        print v;
    }"
}

# Set zoom level
set_zoom() {
    local value="$1"
    clamped=$(clamp "$value")
    hyprctl keyword cursor:zoom_factor "$clamped"
}

case "$1" in
    reset)
        set_zoom 1.0
        ;;
    increase)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 increase STEP"
            exit 1
        fi
        current=$(get_zoom)
        new=$(awk "BEGIN { print $current + $2 }")
        set_zoom "$new"
        ;;
    decrease)
        if [[ -z "$2" ]]; then
            echo "Usage: $0 decrease STEP"
            exit 1
        fi
        current=$(get_zoom)
        new=$(awk "BEGIN { print $current - $2 }")
        set_zoom "$new"
        ;;
    *)
        echo "Usage: $0 {reset|increase STEP|decrease STEP}"
        exit 1
        ;;
esac
