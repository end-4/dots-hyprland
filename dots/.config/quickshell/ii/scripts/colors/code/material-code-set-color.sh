#!/usr/bin/env bash
COLOR_FILE_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/color.txt"
CODE_SETTINGS_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json"

new_color=$(cat "$COLOR_FILE_PATH")

# Try to update the key if it exists
if grep -q '"material-code.primaryColor"' "$CODE_SETTINGS_PATH"; then
    sed -i -E \
        "s/(\"material-code.primaryColor\"\s*:\s*\")[^\"]*(\")/\1${new_color}\2/" \
        "$CODE_SETTINGS_PATH"
else # If the key is not already there, add it
    sed -i '$ s/}/,\n  "material-code.primaryColor": "'${new_color}'"\n}/' "$CODE_SETTINGS_PATH"
    sed -i '$ s/,\n,/,/' "$CODE_SETTINGS_PATH"
fi

