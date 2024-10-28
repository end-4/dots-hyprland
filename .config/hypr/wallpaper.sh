# !/bin/bash

# This script will randomly go through the files of a directory, setting it
# up as the wallpaper at regular intervals
#
# NOTE: this script is in bash (not posix shell), because the RANDOM variable
# we use is not defined in posix

# if [[ $# -lt 1 ]] || [[ ! -d $1   ]]; then
# 	echo "Usage:
# 	$0 <dir containg images>"
# 	exit 1
# fi

# Edit bellow to control the images transition
export SWWW_TRANSITION_FPS=75
export SWWW_TRANSITION_STEP=5
swww-daemon

# This controls (in seconds) when to switch to the next image
INTERVAL=3600

while true; do
	find ~/Imagens/pictures/Imagens/* -type f | shuf -n1 \
		| while read -r img; do
			echo "$((RANDOM % 1000)):$img"
		done \
		| sort -n | cut -d':' -f2- \
		| while read -r img; do
			swww img "$img" \
			--transition-bezier .43,1.19,1,.4 \
			--transition-type grow \
			--transition-duration 1 \
			--transition-fps 75 \
			--transition-pos bottom-right ;
			sh /home/lucas/.config/ags/scripts/color_generation/colorgen.sh "${img}" --apply --smart;
			sleep $INTERVAL
		done
done
