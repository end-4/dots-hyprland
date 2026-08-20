#!/usr/bin/env bash

get_pictures_dir() {
    if command -v xdg-user-dir &> /dev/null; then
        xdg-user-dir PICTURES
        return
    fi

    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
    if [ -f "$config_file" ]; then
        local pictures_path
        pictures_path=$(source "$config_file" >/dev/null 2>&1; echo "$XDG_PICTURES_DIR")
        echo "${pictures_path/#\$HOME/$HOME}"
        return
    fi

    echo "$HOME/Pictures"
}

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
PICTURES_DIR=$(get_pictures_dir)
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$PICTURES_DIR/Wallpapers"

# The endpoint sits behind Cloudflare, which sometimes answers with an HTML
# challenge page instead of JSON (see #3590). Without these guards the script
# cascaded: jq parse error, division by zero, curl with an empty URL, then
# matugen/switchwall choking on a nonexistent image file. A failure should be
# ONE clear notification, not a broken wallpaper state.
response=$(curl -sf -A "Mozilla/5.0 (X11; Linux x86_64)" -H "Accept: application/json"     "https://osu.ppy.sh/api/v2/seasonal-backgrounds") || response=""
images=$(echo "$response" | jq '.backgrounds | length' -r 2>/dev/null) || images=0
if [ -z "$images" ] || [ "$images" -eq 0 ] 2>/dev/null; then
    notify-send -t 8000 -a "Wallpaper switcher" "osu! seasonal backgrounds unreachable"         "The API refused the request (Cloudflare challenge). Try again later." 2>/dev/null || true
    exit 1
fi
randomIndex=$((RANDOM % images));
link=$(echo "$response" | jq ".backgrounds[$randomIndex].url" -r)
ext=$(echo "$link" | awk -F. '{print $NF}')
downloadPath="$PICTURES_DIR/Wallpapers/random_wallpaper.$ext"
illogicalImpulseConfigPath="$HOME/.config/illogical-impulse/config.json"
currentWallpaperPath=$(jq -r '.background.wallpaperPath' $illogicalImpulseConfigPath)
if [ "$downloadPath" == "$currentWallpaperPath" ]; then
    downloadPath="$PICTURES_DIR/Wallpapers/random_wallpaper-1.$ext"
fi
if ! curl -sf "$link" -o "$downloadPath"; then
    notify-send -t 8000 -a "Wallpaper switcher" "osu! background download failed" "$link" 2>/dev/null || true
    exit 1
fi
"$SCRIPT_DIR/../switchwall.sh" --image "$downloadPath"
