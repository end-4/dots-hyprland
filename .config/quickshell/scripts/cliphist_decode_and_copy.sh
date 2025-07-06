#!/usr/bin/env bash

# Script to decode a cliphist entry and pipe it to wl-copy.
# Expects the raw cliphist entry string as the first argument.

set -e # Exit on error

ENTRY_STRING="$1"

if [ -z "$ENTRY_STRING" ]; then
  echo "[cliphist_decode_and_copy.sh] Error: No cliphist entry provided."
  exit 1
fi

# Use process substitution or a here-string to safely pass ENTRY_STRING to cliphist decode
# Then pipe its output to wl-copy
if cliphist decode <<< "$ENTRY_STRING" | wl-copy; then
  echo "[cliphist_decode_and_copy.sh] Successfully decoded and copied to clipboard."
  # notify-send "Clipboard" "Item copied from history." -a Shell # Optional notification
else
  echo "[cliphist_decode_and_copy.sh] Error: Failed to decode or copy."
  # notify-send "Clipboard Error" "Failed to copy item from history." -a Shell -u critical # Optional
  exit 1
fi

exit 0
