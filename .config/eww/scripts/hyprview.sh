#!/usr/bin/bash

if [[ "$1" == "--close" ]]; then
    hyprctl keyword monitor eDP-1,1920x1080@60,0x0,1
    hyprctl keyword monitor eDP-1,addreserved,61,0,0,0
else
    hyprctl keyword monitor eDP-1,1920x1080@60,0x0,0.5
    hyprctl keyword monitor eDP-1,addreserved,533,600,960,960
fi
