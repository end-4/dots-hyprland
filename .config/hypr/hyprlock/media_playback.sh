#!/bin/bash

# Directory where the album art will be saved
cache_dir="$HOME/.cache/hyprlock_music"

# Path to the SCSS file to extract $color1 (color will be used for the banner if it's created)
scss_file="$HOME/.local/state/ags/scss/_musicwal.scss"

# Max length for song and artist names
MAX_LENGTH=20

# Function to delete the album art
delete_art() {
  rm -f "$cache_dir/album_art.png" 2>/dev/null
  rm -f "$cache_dir/album_art_resized.png" 2>/dev/null
  rm -f "$cache_dir/banner.png" 2>/dev/null
}

# Extract the color1 value dynamically from the SCSS file (this part is kept but won't be used now)
banner_color=$(grep -oP '\$color1:\s*\K#[0-9A-Fa-f]{6}' "$scss_file" 2>/dev/null)

# Check if the SCSS file contains color or wallpaper
if [[ -z "$banner_color" && ! -s "$scss_file" ]]; then
  # If no color or wallpaper is found, exit without displaying anything
  exit 0
fi

# If no color1 is found in the SCSS file, fallback to a default color
if [[ -z "$banner_color" ]]; then
  banner_color="#53423F" # Fallback color (you can change this)
fi

# Check if playerctl status returns "No players found"
player_status=$(playerctl status 2>&1)

if [[ "$player_status" == *"No players found"* ]]; then
  # If no player is found, delete the album art and exit
  delete_art
  exit 0 # Exit the script as there is no active media
fi

# Get the current song, artist, and grab any URL line from playerctl metadata
song=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)

# Extract any URL line from the metadata output using grep (catch any line with http/https)
album_art_url=$(playerctl metadata 2>/dev/null | grep -oP 'http[s]?://[^\s]+' | head -n 1)

# Ensure the directory ~/.cache/hyprlock/ exists
mkdir -p "$cache_dir" 2>/dev/null

# Define paths for art and banner
album_art_path="$cache_dir/album_art.png"
album_art_path_resized="$cache_dir/album_art_resized.png"
banner_image_path="$cache_dir/banner.png"

# Function to truncate string if it exceeds the max length
truncate_string() {
  local str="$1"
  local length="$2"
  if [[ ${#str} -gt $length ]]; then
    echo "${str:0:$length}..."
  else
    echo "$str"
  fi
}

# Handle the command-line arguments
if [[ "$1" == "--song" ]]; then
  # Truncate and display song name, do NOT generate or resize album art
  echo "$(truncate_string "$song" $MAX_LENGTH)" 2>/dev/null

elif [[ "$1" == "--artist" ]]; then
  # Truncate and display artist name (without generating images)
  echo "$(truncate_string "$artist" $MAX_LENGTH)" 2>/dev/null

elif [[ "$1" == "--art_path" ]]; then
  # Output the full path to the album art, ensure it's generated
  echo "$album_art_path_resized" 2>/dev/null

elif [[ "$1" == "--banner_path" ]]; then
  # Output the full path to the banner image
  echo "$banner_image_path" 2>/dev/null

elif [[ "$1" == "--now_playing" ]]; then
  # Output 'Now playing' text
  echo "Now playing" 2>/dev/null

elif [[ "$1" == "--icon" ]]; then
  # Output the icon text 'library_music'
  echo "music_note" 2>/dev/null

else
  # Default case: generate album art and banner, but without outputting anything
  if [[ -n "$album_art_url" ]]; then
    # Download the album art using curl
    curl -s "$album_art_url" -o "$album_art_path" 2>/dev/null

    # Resize the album art to 1000x1000px
    magick "$album_art_path" -resize 1000x1000\! "$album_art_path_resized" 2>/dev/null

    # Create the background banner with the color from $color1
    magick -size 1920x500 xc:$banner_color "$banner_image_path" 2>/dev/null
  fi
  # No output when run without any flags
fi
