#!/bin/bash
kbl=$(hyprctl devices -j | gojq -r '.keyboards[] | select(.name == "at-translated-set-2-keyboard") | .active_keymap' | cut -c 1-2 | tr 'A-Z' 'a-z')
if [ "$kbl" = "en" ]; then
  echo '🇬🇧'
elif [ "$kbl" = "ru" ]; then
  echo '🇷🇺'
else
  echo $kbl
fi
