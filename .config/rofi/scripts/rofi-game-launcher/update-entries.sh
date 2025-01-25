#!/usr/bin/env bash

# Generates .desktop entries for all installed Steam games with box art for
# the icons to be used with a specifically configured Rofi launcher

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

STEAM_ROOT="$HOME/.local/share/Steam"
APP_PATH="$HOME/.cache/rofi-game-launcher/applications"
SHORTCUT_SCRIPT="$SCRIPT_DIR/get-shortcut.py"

# Fetch all Steam library folders.
steam-libraries() {
  echo "$STEAM_ROOT"

  # Additional library folders are recorded in libraryfolders.vdf
  local libraryfolders="$STEAM_ROOT/steamapps/libraryfolders.vdf"
  # Match directories listed in libraryfolders.vdf (or at least all strings
  # that look like directories)
  grep -oP "(?<=\")/.*(?=\")" "$libraryfolders"
}

# Generate the contents of a .desktop file for a Steam game.
# Expects appid, title, and box art file to be given as arguments
desktop-entry() {
  cat <<EOF
[Desktop Entry]
Name=$2
Exec=$SCRIPT_DIR/splash-menu.sh $1
Icon=$3
Terminal=false
Type=Application
Categories=SteamLibrary;
EOF
}

search_boxart() {
  local appid=$1
  local library=$2

  # Search in the main library cache directory
  local boxart=$STEAM_ROOT/appcache/librarycache/${appid}/library_600x900.jpg

  if [ ! -f "$boxart" ]; then
    # Search for box art inside subfolders recursively
    boxart=$(find "$STEAM_ROOT/appcache/librarycache/${appid}" -type f -name "library_600x900.jpg" 2>/dev/null | head -n 1)
  fi

  echo "$boxart"
}

update-game-entries() {
  local OPTIND=1
  local quiet update

  while getopts 'qf' arg; do
    case ${arg} in
    f) update=1 ;;
    q) quiet=1 ;;
    *)
      echo "Usage: $0 [-f] [-q]"
      echo "  -f: Full refresh; update existing entries"
      echo "  -q: Quiet; Turn off diagnostic output"
      exit
      ;;
    esac
  done

  mkdir -p "$APP_PATH"
  for library in $(steam-libraries); do
    # All installed Steam games correspond with an appmanifest_<appid>.acf file
    if [ -z "$(
      shopt -s nullglob
      echo "$library"/steamapps/appmanifest_*.acf
    )" ]; then
      # Skip empty library folders
      continue
    fi

    for manifest in "$library"/steamapps/appmanifest_*.acf; do
      appid=$(basename "$manifest" | tr -dc "0-9")
      entry=$APP_PATH/${appid}.desktop

      # Don't update existing entries unless doing a full refresh
      if [ -z $update ] && [ -f "$entry" ]; then
        [ -z $quiet ] && echo "Not updating $entry"
        continue
      fi

      title=$(awk -F\" '/"name"/ {print $4}' "$manifest" | tr -d "™®")
      boxart=$(search_boxart "$appid" "$library")

      # Search for custom boxart set through the Steam library
      boxart_custom_candidates=("$STEAM_ROOT"/userdata/*/config/grid/"${appid}"p.{png,jpg})
      for boxart_custom in "${boxart_custom_candidates[@]}"; do
        if [ -e "$boxart_custom" ]; then
          boxart="$boxart_custom"
          [ -z $quiet ] && echo "Using custom boxart for $title: $boxart"
        fi
      done

      # Filter out non-game entries (e.g. Proton versions or soundtracks) by
      # checking for boxart and other criteria
      if [ ! -f "$boxart" ]; then
        [ -z $quiet ] && echo "Skipping $title (No boxart found at $boxart)"
        continue
      fi
      if echo "$title" | grep -qe "Soundtrack"; then
        [ -z $quiet ] && echo "Skipping $title (Soundtrack detected)"
        continue
      fi
      [ -z $quiet ] && echo -e "Generating $entry\t($title) with boxart: $boxart"
      desktop-entry "$appid" "$title" "$boxart" >"$entry"
    done
  done

  # Process shortcuts and create desktop entries
  while IFS=, read -r appid name exe; do
    entry=$APP_PATH/${appid}.desktop
    boxart=$(search_boxart "$appid" "$STEAM_ROOT")

    # Don't update existing entries unless doing a full refresh
    if [ -z $update ] && [ -f "$entry" ]; then
      [ -z $quiet ] && echo "Not updating $entry for shortcut $name"
      continue
    fi

    if [ -f "$boxart" ]; then
      [ -z $quiet ] && echo -e "Generating $entry\t($name) with boxart: $boxart"
      desktop-entry "$appid" "$name" "$boxart" >"$entry"
    else
      [ -z $quiet ] && echo "Skipping $name (No boxart found at $STEAM_ROOT/appcache/librarycache/${appid}/library_600x900.jpg)"
    fi
  done < <(python3 "$SHORTCUT_SCRIPT")

  # Check if no games were found and update the cache file accordingly
  if [ ! "$(ls -A "$APP_PATH")" ]; then
    echo "No installed games found. Updating cache file..."
    echo "# No installed games" >"$APP_PATH/no_games.cache"
  fi

  # Delete entries for games and shortcuts that are no longer installed
  for desktop_entry in "$APP_PATH"/*.desktop; do
    appid=$(basename "$desktop_entry" | tr -dc "0-9")
    game_installed=false
    shortcut_installed=$(python3 "$SHORTCUT_SCRIPT" | grep -c "^$appid,")

    for library in $(steam-libraries); do
      if [ -f "$library/steamapps/appmanifest_${appid}.acf" ]; then
        game_installed=true
        break
      fi
    done

    if [ "$game_installed" = false ] && [ "$shortcut_installed" -eq 0 ]; then
      [ -z $quiet ] && echo "Deleting $desktop_entry (Game or shortcut not installed)"
      rm "$desktop_entry"
    fi
  done
}
# Generate steam shortcut library cache
gen-shortcut-library() {
  python3 "$HOME/.config/rofi/scripts/shortcuts.py"
}

gen-shortcut-library
update-game-entries "$@"
