#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="ii"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

term_alpha=100 #Set this to < 100 make all your terminals transparent
# sleep 0 # idk i wanted some delay or colors dont get applied properly
if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

colornames=''
colorstrings=''
colorlist=()
colorvalues=()

colornames=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f1)
colorstrings=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
colorlist=($colornames)     # Array of color names
colorvalues=($colorstrings) # Array of color values

# Without colors every sed substitution below is a no-op and the templates get
# copied verbatim, leaving literal "$term0 #" placeholders in the generated theme
# files (kitty then errors out with "Invalid color name"). Bail out instead.
if [ ${#colorlist[@]} -eq 0 ]; then
  echo "applycolor: no colors in $STATE_DIR/user/generated/material_colors.scss; keeping existing themes" >&2
  exit 1
fi

apply_kitty() {  
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/kitty-theme.conf" ]; then
    echo "Template file not found for Kitty theme. Skipping that."
    return
  fi
  # Build in a temp file, then move into place. Substituting in-place on the live
  # file leaves it full of unusable "$term0 #" placeholders for the duration of the
  # loop -- and permanently if the script is interrupted -- which is what kitty
  # reports as "Invalid color name".
  mkdir -p "$STATE_DIR"/user/generated/terminal
  local target="$STATE_DIR/user/generated/terminal/kitty-theme.conf"
  local tmp="$target.tmp.$$"
  cp "$SCRIPT_DIR/terminal/kitty-theme.conf" "$tmp"
  # Apply colors
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$tmp"
  done
  mv "$tmp" "$target"

  # Reload. Match on the process name only: 'pgrep -f kitty' also matches any
  # command line that merely mentions kitty, and then 'pidof' comes back empty
  # and kill runs with no arguments.
  local pids
  pids=$(pgrep -x kitty) || return
  [ -n "$pids" ] && kill -SIGUSR1 $pids
}

apply_anyterm() {
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    echo "Template file not found for Terminal. Skipping that."
    return
  fi
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/sequences.txt" "$STATE_DIR"/user/generated/terminal/sequences.txt
  # Apply colors
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/sequences.txt
  done

  sed -i "s/\$alpha/$term_alpha/g" "$STATE_DIR/user/generated/terminal/sequences.txt"

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
      cat "$STATE_DIR"/user/generated/terminal/sequences.txt >"$file"
      } & disown || true
    fi
  done
}

apply_term() {
  apply_anyterm &
  apply_kitty &
}

# Check if terminal theming is enabled in config
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"
if [ -f "$CONFIG_FILE" ]; then
  enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE")
  if [ "$enable_terminal" = "true" ]; then
    apply_term &
  fi
else
  echo "Config file not found at $CONFIG_FILE. Applying terminal theming by default."
  apply_term &
fi

# apply_qt & # Qt theming is already handled by kde-material-colors
