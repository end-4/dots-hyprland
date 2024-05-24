#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$XDG_CONFIG_HOME/ags"

switch() {
	imgpath=$1
	screensizey=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2 | head -1)
	cursorposx=$(hyprctl cursorpos -j | gojq '.x' 2>/dev/null) || cursorposx=960
	cursorposy=$(hyprctl cursorpos -j | gojq '.y' 2>/dev/null) || cursorposy=540
	cursorposy_inverted=$((screensizey - cursorposy))

	if [ "$imgpath" == '' ]; then
		echo 'Aborted'
		exit 0
	fi

	# ags run-js "wallpaper.set('')"
	# sleep 0.1 && ags run-js "wallpaper.set('${imgpath}')" &
	swww img "$imgpath" --transition-step 100 --transition-fps 120 \
		--transition-type grow --transition-angle 30 --transition-duration 1 \
		--transition-pos "$cursorposx, $cursorposy_inverted"
}

if [ "$1" == "--noswitch" ]; then
	imgpath=$(swww query | awk -F 'image: ' '{print $2}')
	# imgpath=$(ags run-js 'wallpaper.get(0)')
elif [[ "$1" ]]; then
	switch $1
else
	# Select and set image (hyprland)
	
    cd "$(xdg-user-dir PICTURES)" || return 1
	switch $(yad --width 1200 --height 800 --file --add-preview --large-preview --title='Choose wallpaper')
fi

# Generate colors for ags n stuff
"$CONFIG_DIR"/scripts/color_generation/colorgen.sh "${imgpath}" --apply --smart
