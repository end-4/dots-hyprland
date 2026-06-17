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

apply_kitty() {  
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/kitty-theme.conf" ]; then
    echo "Template file not found for Kitty theme. Skipping that."
    return
  fi
  # Copy template
  mkdir -p "$STATE_DIR"/user/generated/terminal
  cp "$SCRIPT_DIR/terminal/kitty-theme.conf" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  # Apply colors
  for i in "${!colorlist[@]}"; do
    sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$STATE_DIR"/user/generated/terminal/kitty-theme.conf
  done

  # Reload
  if ! pgrep -f kitty >/dev/null; then
    return
  fi
  kill -SIGUSR1 $(pidof kitty)
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

apply_papirus_folders() {
    PRIMARY=$(grep '^\$primary:' "$STATE_DIR/user/generated/material_colors.scss" | cut -d'#' -f2 | cut -d';' -f1 | tr '[:upper:]' '[:lower:]')

    HUE=$(python3 -c "
import sys
r,g,b = int('$PRIMARY'[0:2],16), int('$PRIMARY'[2:4],16), int('$PRIMARY'[4:6],16)
mx=max(r,g,b); mn=min(r,g,b)
if mx==mn: h=0
elif mx==r: h=(60*((g-b)/(mx-mn)))%360
elif mx==g: h=60*((b-r)/(mx-mn))+120
else: h=60*((r-g)/(mx-mn))+240
print(int(h))
" 2>/dev/null || echo "0")

    if [ "$HUE" -ge 330 ] || [ "$HUE" -lt 20 ]; then COLOR="red"
    elif [ "$HUE" -lt 40 ]; then COLOR="orange"
    elif [ "$HUE" -lt 65 ]; then COLOR="yellow"
    elif [ "$HUE" -lt 150 ]; then COLOR="green"
    elif [ "$HUE" -lt 190 ]; then COLOR="teal"
    elif [ "$HUE" -lt 220 ]; then COLOR="cyan"
    elif [ "$HUE" -lt 255 ]; then COLOR="blue"
    elif [ "$HUE" -lt 290 ]; then COLOR="violet"
    elif [ "$HUE" -lt 330 ]; then COLOR="pink"
    else COLOR="blue"
    fi

    sudo papirus-folders -C "$COLOR" --theme Papirus-Dark
    sudo papirus-folders -C "$COLOR" --theme Papirus-Light
    sudo papirus-folders -C "$COLOR" --theme Papirus
}

apply_term() {
  apply_anyterm &
  apply_kitty &
  apply_papirus_folders &
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
