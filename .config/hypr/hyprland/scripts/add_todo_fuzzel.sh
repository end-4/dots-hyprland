#!/bin/bash

TODO_FILE="$HOME/.local/state/quickshell/user/todo.json"
TMP_FILE="${TODO_FILE}.tmp"

# Prompt for new todo with a small fuzzel window
NEW_TODO="$(fuzzel --dmenu --prompt="Add todo:" --width=20 --lines=0 --font='monospace:size=8')" || exit 1

# Exit if input is empty
[ -z "$NEW_TODO" ] && exit 0

# If the file does not exist or is empty, initialize with []
if [ ! -s "$TODO_FILE" ]; then
  echo "[]" > "$TODO_FILE"
fi

# Append the new todo using jq
jq --arg content "$NEW_TODO" '. += [{"content":$content,"done":false}]' "$TODO_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$TODO_FILE"
