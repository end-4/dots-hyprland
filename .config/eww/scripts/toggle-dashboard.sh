#!/usr/bin/bash
state=$(eww get open_dashboard)

if [[ "$state" -gt "0" || "$1" == "--close" ]]; then
    eww update open_dashboard=0
    sleep 0.1
    eww close dashboard
    eww update cavajson=''
else
    eww open dashboard
    sleep 0.05
    eww update open_dashboard=1
    sleep 0.05
    eww update open_dashboard=2
    sleep 0.05
    eww update open_dashboard=3
fi
