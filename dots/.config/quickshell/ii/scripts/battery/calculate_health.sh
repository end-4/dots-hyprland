#!/bin/bash

# This just guesses that the BAT0 is the actuall battery
full=$(cat /sys/class/power_supply/BAT0/charge_full)
design=$(cat /sys/class/power_supply/BAT0/charge_full_design)

if [ "$design" -gt 0 ]; then # basically if design > 0
    awk "BEGIN { printf \"%.1f\n\", ($full/$design)*100 }"
else
    echo "Error"
fi