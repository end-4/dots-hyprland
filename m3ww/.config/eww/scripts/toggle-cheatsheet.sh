#!/usr/bin/bash
state=$(eww get open_cheatsheet)

if [[ "$state" -gt "0" || "$1" == "--close" ]]; then
    eww update open_cheatsheet=false
    eww close cheatsheet
else
    eww open cheatsheet
    eww update open_cheatsheet=1
    sleep 0.04
    eww update open_cheatsheet=2
    sleep 0.04
    eww update open_cheatsheet=3
fi