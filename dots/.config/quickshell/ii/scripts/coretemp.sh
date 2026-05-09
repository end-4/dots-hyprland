#!/bin/bash
for d in /sys/class/hwmon/hwmon*; do
    name=$(cat "$d/name")
    if [ "$name" = "coretemp" ] || [ "$name" = "k10temp" ]; then
        ln -sf "$d/temp1_input" "$HOME/.config/quickshell/ii/coretemp"
        exit 0
    fi
done
