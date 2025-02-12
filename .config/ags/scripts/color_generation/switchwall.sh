#!/usr/bin/env bash

# Configuration
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ags"
LAST_IMAGE="$HOME/.cache/last_wallpaper.txt"
YAD="yad --width 1200 --height 800 --file --add-preview --large-preview --title='Choose wallpaper'"

# Ensure wallpaper directory exists
mkdir -p "$HOME/Pictures/Wallpapers"

# Validate and set wallpaper
set_wallpaper() {
  [[ -z "$1" || ! -f "$1" ]] && { echo "Invalid image path: $1" >&2; return 1; }
  [[ -f "$LAST_IMAGE" && "$(cat "$LAST_IMAGE")" == "$1" ]] && { echo "Skipping: Same image as last selection."; return; }

  swww img "$1" --transition-fps 144 --transition-type wipe --transition-duration 1
  "$CONFIG_DIR/scripts/color_generation/colorgen.sh" "$1"
  echo "$1" > "$LAST_IMAGE"
}

# Main
img="$1"
[[ -z "$img" ]] && img=$($YAD)
[[ -n "$img" && -f "$img" ]] && set_wallpaper "$img" || exit 1