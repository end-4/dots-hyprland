#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p ~/Pictures/Wallpapers
page=$((1 + RANDOM % 1000)); 
response=$(curl "https://konachan.com/post.json?tags=rating%3Asafe&limit=1&page=$page")
link=$(echo "$response" | jq '.[0].file_url' -r); 
ext=$(echo "$link" | awk -F. '{print $NF}')
downloadPath="$HOME/Pictures/Wallpapers/konachan_random_image.$ext"
curl "$link" -o "$downloadPath"
"$SCRIPT_DIR/switchwall.sh" --image "$downloadPath"
