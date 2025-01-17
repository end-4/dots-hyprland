#!/bin/bash

# Function to get the current resolution
get_current_resolution() {
    local output
    output=$(hyprctl monitors -j)
    local width height refreshRate
    width=$(echo "$output" | jq -r '.[0].width')
    height=$(echo "$output" | jq -r '.[0].height')
    refreshRate=$(echo "$output" | jq -r '.[0].refreshRate')
    echo "$width $height $refreshRate"
}

# Function to update the Hyprland configuration with the new resolution
update_resolution_config() {
    local newWidth="$1"
    local newHeight="$2"
    local newRefreshRate="$3"
    local currentRes
    currentRes=$(get_current_resolution)
    local width height refreshRate
    width=${newWidth:-$(echo "$currentRes" | awk '{print $1}')}
    height=${newHeight:-$(echo "$currentRes" | awk '{print $2}')}
    refreshRate=${newRefreshRate:-$(echo "$currentRes" | awk '{print $3}')}

    local modelineOutput
    modelineOutput=$(gtf "$width" "$height" "$refreshRate")
    local modeline
    modeline=$(echo "$modelineOutput" | grep -oP 'Modeline "\K[^"]+')

    if [ -z "$modeline" ]; then
        echo "Failed to generate modeline"
        exit 1
    fi

    # Extract the resolution and refresh rate from the modeline
    local resolution
    resolution=$(echo "$modeline" | grep -oP '^[0-9]+x[0-9]+')
    local rate
    rate=$(echo "$modeline" | grep -oP '[0-9]+.[0-9]+$')

    if [ -z "$resolution" ] || [ -z "$rate" ]; then
        echo "Failed to extract resolution or refresh rate from modeline"
        exit 1
    fi

    local configPath="${HOME}/.config/hypr/hyprland/general.conf"
    local newConfigContent
    newConfigContent=$(sed "s/^monitor=.*$/monitor=eDP-1, $resolution@$rate, auto, 1/" "$configPath")

    echo "$newConfigContent" > "$configPath"
}

# Main script
echo "Welcome to the Resolution Configurator"
echo ""
echo "  +---------------------------+"
echo "  |  _____                    |"
echo "  | |     |                   |"
echo "  | |     |                   |"
echo "  | |_____|                   |"
echo "  |                           |"
echo "  +---------------------------+"
echo ""
echo "Current resolution and refresh rate:"
currentRes=$(get_current_resolution)
width=$(echo "$currentRes" | awk '{print $1}')
height=$(echo "$currentRes" | awk '{print $2}')
refreshRate=$(echo "$currentRes" | awk '{print $3}')

echo "Width: $width px"
echo "Height: $height px"
echo "Refresh Rate: $refreshRate Hz"

echo ""

read -p "Enter new width (or press Enter to keep current width): " newWidth
read -p "Enter new height (or press Enter to keep current height): " newHeight
read -p "Enter new refresh rate (or press Enter to keep current refresh rate): " newRefreshRate

# Validate inputs (if provided)
if [[ ! "$newWidth" =~ ^[0-9]+$ && -n "$newWidth" ]]; then
    echo "Invalid width value."
    exit 1
fi

if [[ ! "$newHeight" =~ ^[0-9]+$ && -n "$newHeight" ]]; then
    echo "Invalid height value."
    exit 1
fi

if [[ ! "$newRefreshRate" =~ ^[0-9]+$ && -n "$newRefreshRate" ]]; then
    echo "Invalid refresh rate value."
    exit 1
fi

update_resolution_config "$newWidth" "$newHeight" "$newRefreshRate"

echo "Resolution updated successfully."
