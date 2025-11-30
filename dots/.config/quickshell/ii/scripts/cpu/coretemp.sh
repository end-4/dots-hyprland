#!/bin/bash

mkdir -p "${TMPDIR:-/tmp}/quickshell"

for d in /sys/class/hwmon/hwmon*; do
    if [ -f "$d/name" ]; then
        name=$(cat "$d/name")
        if [ "$name" = "coretemp" ] || [ "$name" = "k10temp" ]; then
            # Make symlink to CPU temp
            ln -sf "$d/temp1_input" "/tmp/quickshell/coretemp"
            exit 0
        fi
    fi
done
