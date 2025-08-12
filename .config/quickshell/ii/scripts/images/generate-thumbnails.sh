#!/usr/bin/env sh

# Checks required ImageMagic commands are available or exit fail
if ! for cmd in identify convert; do
  if ! command -V "$cmd" >/dev/null 2>&1; then
    printf 'Missing ImageMagic required command: %s\n' "$cmd"
    false
  fi
done >&2; then
  exit 1
fi

wall_folder=$1
thumbs_folder="$wall_folder/thumbnails"

thumb_width=640
thumb_height=480

# Creates thumbnails directory if not exist
mkdir -p "$thumbs_folder"
rm -rf "$thumbs_folder"/*


for file in "$wall_folder/"*; do
  # If $file = pattern then no match, exit
  [ "$file" = "$wall_folder/*" ] && exit

  # Gets file MIME type or skip file if it fails
  mime_type="$(file -b --mime-type "$file" 2>&1)" || continue

  # Checks what to do based on mime-type
  case $mime_type in
    image/x-xcf) continue ;; # Not supported
    image/*) ;;              # Accept for processing
    *) continue ;;           # Not an image
  esac

  identify -format '%w %h' "$file" | {
    # Reads piped-in width and height
    read -r width height

    if [ "$width" ] && [ "$height" ] && {
      [ "$width" -gt "$thumb_width" ] || [ "$height" -gt "$thumb_height" ]
    }; then
      basename="${file##*/}"
      extension="${basename##*.}"
      ext_less="${basename%.*}"
      thumb_file="${thumbs_folder}/${ext_less}.${extension}"
      printf 'Create thumb file for %s, size: %dx%d\n' \
        "$file" "$width" "$height"
      magick convert -sample "${thumb_width}x${thumb_height}" "$file" "$thumb_file"
    fi
  }
done

notify-send "Wallpaper Selector" "Thumbnails Generated" -u critical -a Shell