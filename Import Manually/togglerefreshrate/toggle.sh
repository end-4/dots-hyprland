#!/bin/bash
#!Toggle between 144hz and 60hz refresh rate according to charging status(change values according to your system.)

while true; do
charger_status=$(acpi -a | cut -d' ' -f3 | cut -d- -f1)

if [ "$charger_status" == "off" ]; then
    hyprctl keyword monitor eDP-1, 1920x1080@60,0x0,1
fi

if [ "$charger_status" == "on" ]; then
    hyprctl keyword monitor eDP-1, 1920x1080@144,0x0,1
fi

    sleep 5
done