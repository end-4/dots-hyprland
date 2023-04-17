#!/usr/bin/bash

hyprctl activewindow -j | gojq -c -M

if [ "$1" == "--once" ]; then
  exit 0
else
  socat -u UNIX-CONNECT:/tmp/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock - | rg --line-buffered "window>>" | while read -r line; do
    hyprctl activewindow -j | gojq -c -M
  done
fi

