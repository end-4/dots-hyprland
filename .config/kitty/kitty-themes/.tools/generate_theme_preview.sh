#!/usr/bin/env bash
# This script generate all preview images for the themes
# In order to capture previews without the to bar start kitty without decorations
# kitty -o hide_window_decorations=yes

# shellcheck source=libcapture.sh
source libcapture.sh

# read theme path from args
id=$1
theme=$2
preview_filename=$3

conf_filename=$(basename "$theme")

lockfile=$(mktemp)

kitty @ set-colors --match id:"$id" "$theme"
kitty @ send-text --match id:"$id" "clear && figlet -f digital -t \"$conf_filename\" && unbuffer ./color_table.sh && rm \"$lockfile\"\n"

# simple sync mechanism, wait for the lockfile to be removed
( echo "$lockfile" | entr "false" 1>/dev/null 2>&1 ) || capture themes "$preview_filename"
