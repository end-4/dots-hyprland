#!/usr/bin/bash
state=$(eww get music_open)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update anim_open_music=false
    eww update music_open=false
    sleep 0.2
    eww close music 2>/dev/null
    eww update cavajson=''
else
    eww update anim_open_music=true
    eww open music
    eww update music_open=true
fi