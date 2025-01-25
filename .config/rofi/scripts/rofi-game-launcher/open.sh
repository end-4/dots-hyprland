#!/usr/bin/env bash

# Open a Rofi game menu whose entries are all installed Steam games

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

GAME_LAUNCHER_CACHE="$HOME/.cache/rofi-game-launcher"
APP_PATH="$HOME/.local/share/applications/rofi-game-launcher"

launcher-open() {
  # Update entries in the background
  "$SCRIPT_DIR/update-entries.sh" -q &

  # Temporarily link then unlink the *.desktop files to the directory
  # where rofi looks for them to avoid having them appear when using
  # rofi normally
  if [ ! -e "$APP_PATH" ]; then
    ln -s "$GAME_LAUNCHER_CACHE/applications" "$APP_PATH"
  fi

  rofi -show drun \
    -theme games \
    -drun-categories SteamLibrary \
    -cache-dir "$GAME_LAUNCHER_CACHE"

  if [ -h "$APP_PATH" ]; then
    rm "$APP_PATH"
  fi

  # Emulate most recently used history by resetting the count
  # to 0 for each application
  sed -i -e 's/^1/0/' "$GAME_LAUNCHER_CACHE/rofi3.druncache"
}

workspace-width() {
  hyprctl monitors -j | jq '.[] | select(.focused == true) | .width'
}

export ROFI_GAME_LAUNCHER_N_ENTRIES=$(($(workspace-width) / 220))
export ROFI_GAME_LAUNCHER_HEIGHT=360

launcher-open
