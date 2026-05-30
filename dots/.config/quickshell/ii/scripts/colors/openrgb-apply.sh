#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
STATE_DIR="$XDG_STATE_HOME/quickshell"
COLOR_FILE="$STATE_DIR/user/generated/color.txt"

if ! command -v openrgb >/dev/null 2>&1; then
    exit 0
fi

if [ ! -f "$CONFIG_FILE" ]; then
    exit 0
fi

openrgb_enabled=$(jq -r '.appearance.openrgb.enable // false' "$CONFIG_FILE")
if [[ "$openrgb_enabled" != "true" ]]; then
    exit 0
fi

if [ ! -f "$COLOR_FILE" ]; then
    exit 0
fi

color=$(tr -d '\n' < "$COLOR_FILE")
color="${color#\#}"
if ! [[ "$color" =~ ^[A-Fa-f0-9]{6}$ ]]; then
    exit 0
fi

mapfile -t device_ids < <(jq -r '.appearance.openrgb.devices // [] | map(select((.enabled // false) == true)) | .[].id' "$CONFIG_FILE")
if [ ${#device_ids[@]} -eq 0 ]; then
    exit 0
fi

pids=()
for device_id in "${device_ids[@]}"; do
    openrgb --device "$device_id" --mode static --color "$color" >/dev/null 2>&1 &
    pids+=("$!")
done

for pid in "${pids[@]}"; do
    wait "$pid" >/dev/null 2>&1 || true
done
