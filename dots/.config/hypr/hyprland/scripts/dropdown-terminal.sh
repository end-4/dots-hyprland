#!/usr/bin/env bash

# Check if the dropdown terminal is already running
if pgrep -f "kitty --class dropdown-terminal" > /dev/null; then
    # If running, just toggle the workspace visibility
    hyprctl dispatch togglespecialworkspace dropdown
else
    # If NOT running, launch it with the custom class
    # The window rules in hyprland.conf will automatically catch it
    # and send it to special:dropdown
    kitty --class dropdown-terminal &
fi