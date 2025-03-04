#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$XDG_CONFIG_HOME/ags"

# Cache DIR
CACHE_DIR="$HOME/.cache/swww"
CACHE_FILE="$CACHE_DIR/wall.$ext"
WALLPAPER_DIR="$HOME/Pictures/Wallpaper"

switch() {
	imgpath=$1
	read scale screenx screeny screensizey < <(hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
	cursorposx=$(hyprctl cursorpos -j | jq '.x' 2>/dev/null) || cursorposx=960
	cursorposx=$(bc <<< "scale=0; ($cursorposx - $screenx) * $scale / 1")
	cursorposy=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null) || cursorposy=540
	cursorposy=$(bc <<< "scale=0; ($cursorposy - $screeny) * $scale / 1")
	cursorposy_inverted=$((screensizey - cursorposy))

	if [ -z "$imgpath" ]; then
		echo 'Aborted'
		exit 0
	fi

	rm -f "$CACHE_DIR"/wall.*
	
	# Get the extension of the image
    ext="${imgpath##*.}"

    # Convert to lowercase
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    # Check if the extension is valid
    if [[ -z "$ext" || ! "$ext" =~ ^(jpg|jpeg|png|bmp|webp)$ ]]; then
        ext="jpg"
    fi

    # Set the cache file
    CACHE_FILE="$CACHE_DIR/wall.$ext"

    # Copy the image to the cache directory
    cp "$imgpath" "$CACHE_FILE"
	
	ln -sf "$CACHE_FILE" "$CACHE_DIR/wallpaper"

	swww img "$imgpath" --transition-step 100 --transition-fps 144 \
		--transition-type outer --transition-angle 30 --transition-duration 1 \
		--transition-pos "$cursorposx, $cursorposy_inverted"
}

if [ "$1" == "--noswitch" ]; then
	imgpath=$(swww query | awk -F 'image: ' '{print $2}')
elif [[ "$1" ]]; then
	switch "$1"
else
	# Get a random image
	imgpath=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" \) | shuf -n 1)
	switch "$imgpath"
fi

# Generate colors for ags n stuff
"$CONFIG_DIR"/scripts/color_generation/colorgen.sh "${imgpath}" --apply --smart
