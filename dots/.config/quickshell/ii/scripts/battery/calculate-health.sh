#!/bin/bash

# This just guesses that the BAT0 is the actuall battery
# because BAT0 is the default for modern systems
full=$(cat /sys/class/power_supply/BAT0/charge_full)
design=$(cat /sys/class/power_supply/BAT0/charge_full_design)

if [ "$design" -gt 0 ]; then # basically if design > 0
    awk "BEGIN { printf \"%.1f\n\", ($full/$design)*100 }"
else
    echo "Error"
fi

# If you have any issues try to find your "real" battery. 
# Run 'ls /sys/class/power_supply'. You may see BATM or BAT1 and no BAT0
# You can check what is what my running 'cat /sys/class/power_supply/{whatever_you_got}/model_name'
