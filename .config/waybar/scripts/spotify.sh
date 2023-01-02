#!/bin/sh
# install playerctl

# player_status=$(playerctl status 2> /dev/null)
# if [ "$player_status" = "Playing" ]; then
#     echo "$(playerctl metadata artist) - $(playerctl metadata title)"
# elif [ "$player_status" = "Paused" ]; then
#     echo " $(playerctl metadata artist) - $(playerctl metadata title)"
# fi

#!/usr/bin/env bash
# exec 2>"$XDG_RUNTIME_DIR/waybar-playerctl.log"
# IFS=$'\n\t'
#
# while true; do
#
# 	while read -r playing position length name artist title arturl hpos hlen; do
# 		# remove leaders
# 		playng=${playing:1} position=${position:1} length=${length:1} name=${name:1}
# 		artist=${artist:1} title=${title:1} arturl=${arturl:1} hpos=${hpos:1} hlen=${hlen:1}
#
# 		# build line
# 		line="${artist:+$artist ${title:+- }}${title:+$title }${hpos:+$hpos${hlen:+|}}$hlen"
#
# 		# json escaping
# 		line="${line//\"/\\\"}"
# 		((percentage = length ? (100 * (position % length)) / length : 0))
#
#     if [ -z "$line" ]
#     then
#         text=""
#     else
#         text="<span color='#1db954'></span> $line"
#     fi
# #
# 		# integrations for other services (nwg-wrapper)
# 		if [[ $title != "$ptitle" || $artist != "$partist" || $parturl != "$arturl" ]]; then
# 			typeset -p playing length name artist title arturl >"$XDG_RUNTIME_DIR/waybar-playerctl.info"
# 			pkill -8 nwg-wrapper
# 			ptitle=$title partist=$artist parturl=$arturl
# 		fi
#
# 		# exit if print fails
# 		printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%s}\n' \
# 			"$text" "$playing $name | $line" "$percentage" "$percentage" || break 2
#
# 	done < <(
# 		# requires playerctl>=2.0
# 		# Add non-space character ":" before each parameter to prevent 'read' from skipping over them
# 		playerctl --follow metadata --player playerctld --format \
# 			$':{{emoji(status)}}\t:{{position}}\t:{{mpris:length}}\t:{{playerName}}\t:{{markup_escape(artist)}}\t:{{markup_escape(title)}}\t:{{mpris:artUrl}}\t:{{duration(position)}}\t:{{duration(mpris:length)}}' &
# 		echo $! >"$XDG_RUNTIME_DIR/waybar-playerctl.pid"
# 	)
#
# 	# no current players
# 	# exit if print fails
# 	echo '<span foreground=#dc322f>⏹</span>' || break
# 	sleep 15
#
# done
#
# kill "$(<"$XDG_RUNTIME_DIR/waybar-playerctl.pid")"

#!/usr/bin/env bash
# exec 2>"$XDG_RUNTIME_DIR/waybar-playerctl.log"
# IFS=$'\n\t'
#
# while true; do
#
# 	while read -r playing position length name artist title arturl hpos hlen; do

while true; do

	player_status=$(playerctl status 2>/dev/null)

	if [ -z "$(playerctl metadata album)" ]; then
		if [ "$player_status" = "Playing" ]; then
			echo "$(playerctl metadata artist) - $(playerctl metadata title)"
		elif [ "$player_status" = "Paused" ]; then
			echo " $(playerctl metadata artist) - $(playerctl metadata title)"
    else
			echo ""
		fi
	else
		if [ "$player_status" = "Playing" ]; then
			echo "<span color='#1db954'></span> $(playerctl metadata artist) - $(playerctl metadata title)"
		elif [ "$player_status" = "Paused" ]; then
			echo "<span color='#1db954'></span>  $(playerctl metadata artist) - $(playerctl metadata title)"
    else
			echo ""
		fi
	fi

	sleep 1

done

# done
#
# kill "$(<"$XDG_RUNTIME_DIR/waybar-playerctl.pid")"
