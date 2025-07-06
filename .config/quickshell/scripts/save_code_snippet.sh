#!/usr/bin/env bash

# Script to safely save a code snippet to the Downloads directory.
# Arguments:
# $1: Proposed filename (e.g., "code.txt" or "script.py")
# $2: Content of the code snippet

PROPOSED_FILENAME="$1"
CONTENT="$2" # Content is passed as the second argument

# Validate arguments
if [ -z "$PROPOSED_FILENAME" ]; then
  echo "[save_code_snippet.sh] Error: No filename specified."
  notify-send "Save Code Error" "No filename specified." -a Shell -u critical
  exit 1
fi

if [ -z "$CONTENT" ]; then
  # Allow empty content, but log it.
  echo "[save_code_snippet.sh] Warning: Content is empty for filename '$PROPOSED_FILENAME'."
fi

# Determine the downloads directory
DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"

# Sanitize the PROPOSED_FILENAME to prevent path traversal and remove unsafe characters.
# Allow alphanumeric, dots, underscores, hyphens. Remove others.
SANITIZED_BASENAME=$(basename "$PROPOSED_FILENAME") # Ensure it's just a filename
SANITIZED_FILENAME=$(echo "$SANITIZED_BASENAME" | sed 's/[^a-zA-Z0-9._-]/_/g')

if [ -z "$SANITIZED_FILENAME" ]; then
  SANITIZED_FILENAME="code_snippet.txt" # Fallback filename
  echo "[save_code_snippet.sh] Warning: Proposed filename was empty or invalid after sanitization. Using '$SANITIZED_FILENAME'."
fi

# Prevent excessively long filenames (e.g., 200 chars max)
MAX_FILENAME_LEN=200
if [ "${#SANITIZED_FILENAME}" -gt "$MAX_FILENAME_LEN" ]; then
  SANITIZED_FILENAME="${SANITIZED_FILENAME:0:$MAX_FILENAME_LEN}"
  echo "[save_code_snippet.sh] Warning: Truncated filename to $MAX_FILENAME_LEN characters."
fi


FINAL_PATH="$DOWNLOAD_DIR/$SANITIZED_FILENAME"

# Ensure download directory exists
mkdir -p "$DOWNLOAD_DIR"

# Write the content to the file. Using printf is safer than echo for arbitrary content.
if printf '%s' "$CONTENT" > "$FINAL_PATH"; then
  echo "[save_code_snippet.sh] Successfully saved to '$FINAL_PATH'."
  notify-send "Code saved to file" "$FINAL_PATH" -a Shell
else
  echo "[save_code_snippet.sh] Error: Failed to save to '$FINAL_PATH'."
  notify-send "Save Code Error" "Failed to save to '$FINAL_PATH'." -a Shell -u critical
  exit 1
fi

exit 0
