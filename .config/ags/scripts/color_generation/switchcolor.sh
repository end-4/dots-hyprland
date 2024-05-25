#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/ags"
CACHE_DIR="$XDG_CACHE_HOME/ags"
STATE_DIR="$XDG_STATE_HOME/ags"

if [ "$1" == "--pick" ]; then
  color=$(hyprpicker --no-fancy)
elif [[ "$1" = "#"* ]]; then # this is a color
  color=$1
else
  color=$(cut -f1 "$STATE_DIR/user/color.txt")
fi

# Generate colors for ags n stuff
"$CONFIG_DIR"/scripts/color_generation/colorgen.sh "${color}" --apply
