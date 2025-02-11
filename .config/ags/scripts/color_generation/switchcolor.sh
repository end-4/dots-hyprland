#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/ags"
STATE_DIR="$XDG_STATE_HOME/ags"
COLORMODE_FILE_DIR="$STATE_DIR/user/colormode.txt"

"$CONFIG_DIR"/scripts/color_generation/colorgen.sh "$(cat "$STATE_DIR/user/current_wallpaper.txt")" &
