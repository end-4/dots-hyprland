#!/usr/bin/env bash
COLOR_FILE_PATH="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/color.txt"

# Define an array of possible VSCode settings file paths for various forks
settings_paths=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/VSCodium/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code - OSS/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Code - Insiders/User/settings.json"
    "${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User/settings.json"
    # Add more paths as needed for other forks
)

new_color=$(cat "$COLOR_FILE_PATH")

# Loop through each settings file path
for CODE_SETTINGS_PATH in "${settings_paths[@]}"; do
    if [[ -f "$CODE_SETTINGS_PATH" ]]; then
        # Try to update the key if it exists
        if grep -q '"material-code.primaryColor"' "$CODE_SETTINGS_PATH"; then
            sed -i -E \
                "s/(\"material-code.primaryColor\"\s*:\s*\")[^\"]*(\")/\1${new_color}\2/" \
                "$CODE_SETTINGS_PATH"
        else # If the key is not already there, add it
            sed -i '$ s/}/,\n  "material-code.primaryColor": "'${new_color}'"\n}/' "$CODE_SETTINGS_PATH"
            sed -i '$ s/,\n,/,/' "$CODE_SETTINGS_PATH"
        fi
    fi
done

