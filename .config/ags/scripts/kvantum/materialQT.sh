#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/ags"
CACHE_DIR="$XDG_CACHE_HOME/ags"
STATE_DIR="$XDG_STATE_HOME/ags"

get_light_dark() {
	lightdark=""
	if [ ! -f "$STATE_DIR/user/colormode.txt" ]; then
		echo "" >"$STATE_DIR/user/colormode.txt"
	else
		lightdark=$(sed -n '1p' "$STATE_DIR/user/colormode.txt")
	fi
	echo "$lightdark"
}

apply_qt() {
	# Check if the theme exists
	FOLDER_PATH="$XDG_CONFIG_HOME/Kvantum/Colloid/"

	if [ ! -d "$FOLDER_PATH" ]; then
		# Send a notification
		notify-send "Colloid-kde theme required" " The folder '$FOLDER_PATH' does not exist."
		exit 1 # Exit the function if the folder does not exist
	fi

	lightdark=$(get_light_dark)
	if [ "$lightdark" = "light" ]; then
		# apply ligght colors
		cp "$XDG_CONFIG_HOME/Kvantum/Colloid/Colloid.kvconfig" "$XDG_CONFIG_HOME/Kvantum/MaterialAdw/MaterialAdw.kvconfig"
		python "$CONFIG_DIR/scripts/kvantum/adwsvg.py"

	else
		#apply dark colors
		cp "$XDG_CONFIG_HOME/Kvantum/Colloid/ColloidDark.kvconfig" "$XDG_CONFIG_HOME/Kvantum/MaterialAdw/MaterialAdw.kvconfig"
		python "$CONFIG_DIR/scripts/kvantum/adwsvgDark.py"
	fi
}

apply_qt
