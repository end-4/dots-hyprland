#!/bin/bash


# Script for Battery Stats
if [ "$1" == "-bat" ]; then
	# Get the current battery percentage
	battery_percentage=$(cat /sys/class/power_supply/BAT1/capacity)

	# Get the battery status (Charging or Discharging)
	battery_status=$(cat /sys/class/power_supply/BAT1/status)

	# Define the battery icons for each 10% segment
	battery_icons=("󰂃" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰁹")

	# Define the charging icon
	charging_icon="󰂄"

	# Calculate the index for the icon array
	icon_index=$((battery_percentage / 10))

	# Get the corresponding icon
	battery_icon=${battery_icons[icon_index]}

	# Check if the battery is charging
	if [ "$battery_status" = "Charging" ]; then
		battery_icon="$charging_icon"
	fi

	# Output the battery percentage and icon
	echo "$battery_icon $battery_percentage%"





# Script for Music Stats
elif [ "$1" == "-music" ]; then

	# Function to get metadata using playerctl
	get_metadata() {
		key=$1
		playerctl metadata --format "{{ $key }}" 2>/dev/null
	}

	# Check for arguments

	# Function to determine the source and return an icon and text
	get_source_info() {
		trackid=$(get_metadata "mpris:trackid")
		if [[ "$trackid" == *"firefox"* ]]; then
			echo -e "Firefox 󰈹"
		elif [[ "$trackid" == *"spotify"* ]]; then
			echo -e "Spotify "
		elif [[ "$trackid" == *"chromium"* ]]; then
			echo -e "Chrome "
		else
			echo "Source    "
		fi
	}

	# Parse the argument
	case "$2" in
	--title)
		title=$(get_metadata "xesam:title")
		if [ -z "$title" ]; then
			echo "Nothing Playing"
		else
			ten="          "
			thirty="$ten$ten$ten"
			len=${#title}
			end="   "
			if ((len>13)); then
				len=13
				end="..."
			fi
			title="${title:0:13}${thirty:0:$((13 - len))}"
			echo "${title}${end}"
			#echo "${title:0:18}" # Limit the output to 50 characters
		fi
		;;
	--arturl)
		url=$(get_metadata "mpris:artUrl")
		if [ -z "$url" ]; then
			echo ""
		else
			if [[ "$url" == file://* ]]; then
				url=${url#file://}
			elif [[ "$url" == https://i.scdn.co/* ]]; then
				cd "$HOME/.config/hypr/hyprlock"
				temp_url=$(echo $url | awk -F '/' '{print $5}')
				if [ ! -f "${temp_url}" ]; then
					rm *[^.jpg][^.sh][^.webp] >/dev/null 2>/dev/null
					wget $url -O $temp_url >/dev/null 2>/dev/null
				fi
				url="$HOME/.config/hypr/hyprlock/${temp_url}"
			fi
			echo "$url"
		fi
		;;
	--artist)
		artist=$(get_metadata "xesam:artist")
		if [ -z "$artist" ]; then
			echo ""
		else
			ten="          "
			thirty="$ten$ten$ten"
			len=${#artist}
			end="   "
			if ((len>10)); then
				len=10
				end="..."
			fi
			artist="${artist:0:10}${thirty:0:$((10 - len))}"
			echo "${artist}${end}"
			# echo "${artist:0:30}" # Limit the output to 50 characters
		fi
		;;
	--length)
		length=$(get_metadata "mpris:length")
		if [ -z "$length" ]; then
			echo ""
		else
			# Convert length from microseconds to a more readable format (seconds)
			echo "$(echo "scale=2; $length / 1000000 / 60" | bc) m"
		fi
		;;
	--status)
		status=$(playerctl status 2>/dev/null)
		if [[ $status == "Playing" ]]; then
			echo "󰎆"
		elif [[ $status == "Paused" ]]; then
			echo "󱑽"
		else
			echo ""
		fi
		;;
	--album)
		album=$(playerctl metadata --format "{{ xesam:album }}" 2>/dev/null)
		if [[ -n $album ]]; then
			echo "$album"
		else
			status=$(playerctl status 2>/dev/null)
			if [[ -n $status ]]; then
				echo "Not album"
			else
				echo ""
			fi
		fi
		;;
	--source)
		get_source_info
		;;
	*)
		echo "Invalid parameter: $2"
		echo "Usage: $0 -music --title | --url | --artist | --length | --album | --source"
		exit 1
		;;
	esac

else
	echo "Invalid option: $1"
	echo "Usage: $0 -bat | -music"
	exit 1
fi