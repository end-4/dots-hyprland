#!/bin/bash

get_current_resolution() {
    local outputs width height refreshRate
    outputs=$(hyprctl monitors -j)
    width=$(echo "$outputs" | jq -r '.[0].width')
    height=$(echo "$outputs" | jq -r '.[0].height')
    refreshRate=$(echo "$outputs" | jq -r '.[0].refreshRate')
    echo "$width $height $refreshRate"
}

update_resolution_config() {
    local newWidth="$1" newHeight="$2" newRefreshRate="$3"
    local currentRes width height refreshRate modelineOutput modeline resolution rate configPath="${HOME}/.config/hypr/hyprland/general.conf"

    currentRes=$(get_current_resolution)

    width=${newWidth:-$(echo "$currentRes" | awk '{print $1}')}
    height=${newHeight:-$(echo "$currentRes" | awk '{print $2}')}
    refreshRate=${newRefreshRate:-$(echo "$currentRes" | awk '{print $3}')}

    modelineOutput=$(gtf "$width" "$height" "$refreshRate")
    modeline=$(echo "$modelineOutput" | grep -oP 'Modeline "\K[^"]+')

    if [ -z "$modeline" ]; then
        echo "Error: Failed to generate modeline."
        exit 1
    fi

    resolution=$(echo "$modeline" | grep -oP '^[0-9]+x[0-9]+')
    rate=$(echo "$modeline" | grep -oP '[0-9]+.[0-9]+$')

    if [ -z "$resolution" ] || [ -z "$rate" ]; then
        echo "Error: Failed to extract resolution or refresh rate."
        exit 1
    fi

    sed "s/^monitor=.*$/monitor=eDP-1, $resolution@$rate, auto, 1/" "$configPath"
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

read -p "Enter new width (or press Enter to keep current width): " newWidth
read -p "Enter new height (or press Enter to keep current height): " newHeight
read -p "Enter new refresh rate (or press Enter to keep current refresh rate): " newRefreshRate

if [[ -n "$newWidth" && ! "$newWidth" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid width value."
    exit 1
fi

if [[ -n "$newHeight" && ! "$newHeight" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid height value."
    exit 1
fi

if [[ -n "$newRefreshRate" && ! "$newRefreshRate" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid refresh rate value."
    exit 1
fi

update_resolution_config "$newWidth" "$newHeight" "$newRefreshRate"

echo "Resolution updated successfully."
