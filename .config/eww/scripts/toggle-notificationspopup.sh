#!/usr/bin/bash
if [[ "$1" == "--open" ]]; then
    eww open notificationspopup
    eww update open_notificationspopup=true
    exit
fi

state=$(eww get open_notificationspopup)
if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update open_notificationspopup=false
    sleep 0.15
    eww close notificationspopup
else
    cd ~/.config/eww || exit
    eww open notificationspopup
    eww update open_notificationspopup=true
fi
