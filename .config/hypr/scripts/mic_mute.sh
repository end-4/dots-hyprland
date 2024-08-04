#!/bin/bash
status=$(cat /sys/class/leds/platform::micmute/brightness)
if [ "$status" -eq 0 ]; then
    new_status=1
else
    new_status=0
fi
echo $new_status > /sys/class/leds/platform::micmute/brightness
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
