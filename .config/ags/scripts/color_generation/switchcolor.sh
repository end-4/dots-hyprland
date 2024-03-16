#!/usr/bin/env bash

if [ "$1" == "--pick" ]; then
  color=$(hyprpicker --no-fancy)
else
  color=$(cut -f1 "${HOME}/.cache/ags/user/color.txt")
fi

# Generate colors for ags n stuff
"$HOME"/.config/ags/scripts/color_generation/colorgen.sh "${color}" --apply
