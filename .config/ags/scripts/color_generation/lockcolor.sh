#!/usr/bin/env bash

# Path to file SCSS and Hyprlock configuration
SCSS_FILE="$HOME/.local/state/ags/scss/_material.scss"
TEMPLATE_CONF="$HOME/.config/ags/scripts/templates/hypr/hyprlock.conf"
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"

# Reading HEX from variable $primary and $term9 in _material.scss
PRI_COLOR=$(grep -Po '\$primary:\s*#\K[0-9A-Fa-f]+' "$SCSS_FILE")
SEC_COLOR=$(grep -Po '\$term9:\s*#\K[0-9A-Fa-f]+' "$SCSS_FILE")

# Make sure the color is not empty
if [[ -z "$PRI_COLOR" || -z "$SEC_COLOR" ]]; then
    echo "Failed to get color from _material.scss"
    exit 1
fi

# Change color format to rgba
RGBA_PRI_COLOR=$(printf "rgba(%d, %d, %d, 1.0)" 0x${PRI_COLOR:0:2} 0x${PRI_COLOR:2:2} 0x${PRI_COLOR:4:2})
RGBA_SEC_COLOR=$(printf "rgba(%d, %d, %d, 1.0)" 0x${SEC_COLOR:0:2} 0x${SEC_COLOR:2:2} 0x${SEC_COLOR:4:2})

# Update color template in hyprlock.conf
if [[ -f "$TEMPLATE_CONF" ]]; then
    sed -i "s|\(\$text_color = \).*|\1${RGBA_PRI_COLOR}|" "$TEMPLATE_CONF"
    sed -i "s|\(\$entry_border_color = \).*|\1${RGBA_PRI_COLOR}|" "$TEMPLATE_CONF"
    sed -i "s|\(\$entry_color = \).*|\1${RGBA_PRI_COLOR}|" "$TEMPLATE_CONF"
    sed -i "s|\(\$clock_color = \).*|\1${RGBA_SEC_COLOR}|" "$TEMPLATE_CONF"
    echo "Updated: $TEMPLATE_CONF"

    # give some delay
    sleep 1
    
    # Copy the updated template to hyprlock.conf
    cp "$TEMPLATE_CONF" "$HYPRLOCK_CONF"
    echo "Copied $TEMPLATE_CONF to $HYPRLOCK_CONF"
else
    echo "File not found: $TEMPLATE_CONF"
    exit 1
fi

