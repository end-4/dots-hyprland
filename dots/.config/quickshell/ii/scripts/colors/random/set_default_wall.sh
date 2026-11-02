#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DEFAULT_WALLPAPER="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME/assets/images/default_wallpaper.png"

if [ ! -f "$DEFAULT_WALLPAPER" ]; then
  echo "Error: Default wallpaper not found at $DEFAULT_WALLPAPER"
  exit 1
fi

"$SCRIPT_DIR/../switchwall.sh" --image "$DEFAULT_WALLPAPER"
