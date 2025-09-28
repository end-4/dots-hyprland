#!/bin/bash

CONF_FILE_CUSTOM="$HOME/.config/hypr/custom/general.conf"
CONF_FILE_DEFAULT="$HOME/.config/hypr/hyprland/general.conf"
KEY=$1

# Check in custom config first
if [ -f "$CONF_FILE_CUSTOM" ] && grep -q "^\s*$KEY\s*=" "$CONF_FILE_CUSTOM"; then
    grep "^\s*$KEY\s*=" "$CONF_FILE_CUSTOM" | sed "s/^\s*$KEY\s*=\s*//" | tr -d ' '
elif [ -f "$CONF_FILE_DEFAULT" ]; then
    # Fallback to default config
    grep "^\s*$KEY\s*=" "$CONF_FILE_DEFAULT" | sed "s/^\s*$KEY\s*=\s*//" | tr -d ' '
fi
