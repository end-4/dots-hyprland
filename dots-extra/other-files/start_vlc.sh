#!/bin/bash

# Inicia o VLC: -Z (Aleatório), -L (Loop), e desassocia do shell
vlc -Z -L --no-playlist-autostart  /mnt/ssd2/music & disown
sleep 0.1
hyprctl dispatch togglespecialworkspace

exit
