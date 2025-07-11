#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_light_dark() {
	current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
	if [[ "$current_mode" == "prefer-dark" ]]; then
		echo "dark"
	else
		echo "light"
	fi
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
