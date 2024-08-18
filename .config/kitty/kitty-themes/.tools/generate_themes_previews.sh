#!/usr/bin/env bash
# This script generate all preview images for the themes

root="$(git rev-parse --show-toplevel)"
tools="$root/.tools"

PATH=$tools:$PATH

# new kitty window, return its id
id=$(kitty @ new-window --title themes --window-type os --cwd "$tools")
# start bash without reading the profile nor the configuration
kitty @ send-text --match id:"$id" "/usr/bin/env bash --noprofile --norc\n"
kitty @ set-font-size 24

# save all preview in this directory
previews="$root/_previews"
if [ ! -d "$previews" ]; then
  mkdir "$previews"
fi

while read -r theme
do
  echo "Genereting theme preview for $theme"
  preview_directory=$previews/$(basename "${theme%.*}")
  [ ! -d "$preview_directory" ] && mkdir "$preview_directory"
  preview_filename=$previews/$(basename "${theme%.*}")/preview.png
  generate_theme_preview.sh "$id" "$theme" "$preview_filename"
  mogrify -resize 1024x\> "$preview_filename"
done < /dev/stdin

kitty @ close-window --match id:"$id"
kitty @ set-font-size 16
