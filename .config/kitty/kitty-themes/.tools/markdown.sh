#!/usr/bin/env bash

previews_root=$1
# usually this value: https://raw.githubusercontent.com/dexpota/kitty-themes-website/master
url_root=$2

for f in $(find "$previews_root/previews" -maxdepth 1 -mindepth 1 -type d | sort); do
	preview_file="$f"/preview.png
	theme=$(basename $f)
	relative_path=$(realpath --relative-to="$previews_root" "$preview_file")
	header=`basename $theme | sed 's/_/ /g'`
	image="![image]($url_root/$relative_path)"
	echo \#\# $header
	echo $image
done
