#!/usr/bin/env bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

usage() {
  echo "Open Rofi launch menu for a Steam game with the given appid"
  echo "Usage: $0 <appid>"
  exit
}

[ "$#" -ne 1 ] && usage

appid="$1"

# Populate arrays containing the menu information
declare -a entries
declare -A operation icon

create-menu-entries() {
  local entry_struct
  # shellcheck disable=SC2016
  local menu=(
    # Entry              Icon Operation
    '("Play"             ""  "steam steam://rungameid/$appid")'
    '("Open in library"  ""  "steam steam://nav/games/details/$appid")'
    '("Achievements"     ""  "steam steam://url/SteamIDAchievementsPage/$appid")'
    '("News"             ""  "steam steam://appnews/$appid")'
    '("Back"             ""  "$SCRIPT_DIR/open.sh")'
  )

  # Create associative arrays out of the fake multidimensional array
  for entry in "${menu[@]}"; do
    eval entry_struct="${entry[*]}"
    name="${entry_struct[0]}"
    entries+=("$name")
    icon[$name]="${entry_struct[1]}"
    operation[$name]="${entry_struct[2]}"
  done
}

# Source the Python script and update "Play" option for shortcuts
source-python-script() {
  while IFS=, read -r shortcut_appid name exe; do
    if [ "$shortcut_appid" == "$appid" ]; then
      operation["Play"]="$exe"
      break
    fi
  done < <(python3 "$SCRIPT_DIR/get-shortcut.py")
}

# Open the Rofi game menu
rofi-menu() {
  for entry in "${entries[@]}"; do
    echo -e "${icon[$entry]}\t$entry"
  done | rofi -dmenu -theme game-splash-menu
}

# Execute the command corresponding with the selected menu entry
rofi-select() {
  local selection="${1#*$'\t'}"
  [ -z "$selection" ] && exit 1
  eval "${operation[$selection]}"
}

# Get the width of the current workspace
workspace-width() {
  hyprctl -j monitors | jq '.[] | select(.focused == true) | .width'
}

# Generate the banner image used as a backdrop in the Rofi menu
update-banner-image() {
  "$SCRIPT_DIR/banner-image.sh" \
    -w "$(workspace-width)" \
    -h "$ROFI_GAME_LAUNCHER_HEIGHT" \
    -a "$appid"
}

update-banner-image
create-menu-entries
source-python-script
rofi-select "$(rofi-menu)"
