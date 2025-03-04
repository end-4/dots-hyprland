#!/usr/bin/env bash

# Path
SCSS_FILE="$HOME/.local/state/ags/scss/_material.scss"
CAVA_CONFIG="$HOME/.config/cava/config"

# Pick Color
PRIMARY_COLOR=$(grep -oP '\$primary:\s*#\K[0-9A-Fa-f]+' "$SCSS_FILE")

# Update cava config
if [[ -n "$PRIMARY_COLOR" ]]; then
    sed -i "s/^foreground\s*=.*/foreground = '#$PRIMARY_COLOR'/" "$CAVA_CONFIG"
fi

# Refresh cava
pkill -USR1 cava