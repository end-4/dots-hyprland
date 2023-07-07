#!/usr/bin/bash
state=$(eww get open_bottomsheet)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update open_bottomsheet=false
    sleep 0.2
    eww close bottomsheet_back 2>/dev/null
    eww close bottomsheet 2>/dev/null
    eww update cavajson='[]'
else
    eww open bottomsheet_back
    eww open bottomsheet
    eww update open_bottomsheet=true
fi
