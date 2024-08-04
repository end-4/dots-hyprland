#!/usr/bin/env bash

export STATUS_FILE="$XDG_RUNTIME_DIR/touchpad.status"

enable_touchpad() {
    printf "true" >"$STATUS_FILE"
    notify-send -i '/usr/share/icons/OneUI-dark/24/devices/input-touchpad-on.svg' -u normal "Touchpad Enabled"
    hyprctl keyword '$HYPR_TOUCHPAD_ENABLED' "true" -r
}

disable_touchpad() {
    printf "false" >"$STATUS_FILE"
    notify-send -i '/usr/share/icons/OneUI-dark/24/devices/input-touchpad-off.svg' -u normal "Touchpad Disabled"
    hyprctl keyword '$HYPR_TOUCHPAD_ENABLED' "false" -r
}

if ! [ -f "$STATUS_FILE" ]; then
  enable_touchpad
else
  if [ $(cat "$STATUS_FILE") = "true" ]; then
    disable_touchpad
  elif [ $(cat "$STATUS_FILE") = "false" ]; then
    enable_touchpad
  fi
fi
