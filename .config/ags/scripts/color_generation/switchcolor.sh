#!/usr/bin/env bash

color=$(hyprpicker --no-fancy)

# Generate colors for ags n stuff
"$HOME"/.config/ags/scripts/color_generation/colorgen.sh "${color}" --apply
