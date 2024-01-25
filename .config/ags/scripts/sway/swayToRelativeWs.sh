#!/usr/bin/env bash

# Get the current workspace number
current=$(swaymsg -t get_workspaces | gojq '.[] | select(.focused==true) | .num')

# Check if a number was passed as an argument
if [[ "$1" =~ ^[+-]?[0-9]+$ ]]; then
  new_workspace=$((current + $1))
else
  new_workspace=$((current + 1))
fi

# Check if the new workspace number is out of bounds
if [[ $new_workspace -lt 1 ]]; then
  exit 0
fi

# Switch to the new workspace
swaymsg workspace $new_workspace