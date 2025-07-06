#!/usr/bin/env bash

# Script to safely remove and recreate a directory.
# Used by Directories.qml for startup cleanup.
# This script does NOT ask for confirmation as it's for automated cleanup.
# It strictly validates the path against a list of allowed parent directories.

TARGET_DIR="$1"

if [ -z "$TARGET_DIR" ]; then
  echo "[safe_cleanup_dir.sh] Error: No target directory specified."
  exit 1
fi

# Resolve to absolute path as robustly as possible
ABSOLUTE_TARGET_DIR=$(realpath -m "$TARGET_DIR" 2>/dev/null)

if [ -z "$ABSOLUTE_TARGET_DIR" ]; then
  echo "[safe_cleanup_dir.sh] Error: Target directory '$TARGET_DIR' is invalid or cannot be resolved."
  exit 1
fi

# Define allowed parent directories for cleanup.
# These should correspond to the specific directories QuickShell is allowed to clean.
# It's crucial these are absolute paths.
# We'll try to get XDG_CACHE_HOME and XDG_RUNTIME_DIR (for /tmp alternative)
# Fallback to sensible defaults if not set, though Quickshell environment should provide them.
QS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
QS_TMP_DIR="${XDG_RUNTIME_DIR:-/tmp}" # /tmp is a fallback, XDG_RUNTIME_DIR is preferred for user session tmp files

# These paths are derived from Directories.qml properties that are subject to "rm -rf"
# It's critical that these exactly match what Directories.qml intends to clean.
# The paths here MUST be absolute after realpath -m resolution.
ALLOWED_CLEANUP_TARGETS=(
  "$(realpath -m "${QS_CACHE_DIR}/media/coverart")"
  "$(realpath -m "${QS_CACHE_DIR}/media/boorus")"
  "$(realpath -m "${QS_CACHE_DIR}/media/latex")"
  "$(realpath -m "${QS_TMP_DIR}/quickshell/media/cliphist")" # cliphistDecode path from Directories.qml
)

IS_ALLOWED=false
for allowed_target in "${ALLOWED_CLEANUP_TARGETS[@]}"; do
  if [[ "$ABSOLUTE_TARGET_DIR" == "$allowed_target" ]]; then
    IS_ALLOWED=true
    break
  fi
done

if [ "$IS_ALLOWED" = false ]; then
  echo "[safe_cleanup_dir.sh] Error: Target directory '$ABSOLUTE_TARGET_DIR' is not in the allowed list for cleanup."
  echo "[safe_cleanup_dir.sh] Allowed full paths for cleanup are:"
  printf "%s\n" "${ALLOWED_CLEANUP_TARGETS[@]}"
  echo "[safe_cleanup_dir.sh] Error: Target directory '$ABSOLUTE_TARGET_DIR' is not in the allowed list for cleanup."
  # For debugging, list allowed paths:
  # echo "Allowed directories are:"
  # printf "%s\n" "${ALLOWED_PARENT_DIRS[@]}"
  exit 1
fi

# Proceed with rm -rf and mkdir -p
echo "[safe_cleanup_dir.sh] Cleaning up '$ABSOLUTE_TARGET_DIR'..."
rm -rf "$ABSOLUTE_TARGET_DIR"
if [ $? -eq 0 ]; then
  echo "[safe_cleanup_dir.sh] Successfully removed '$ABSOLUTE_TARGET_DIR'."
  mkdir -p "$ABSOLUTE_TARGET_DIR"
  if [ $? -eq 0 ]; then
    echo "[safe_cleanup_dir.sh] Successfully recreated '$ABSOLUTE_TARGET_DIR'."
  else
    echo "[safe_cleanup_dir.sh] Error: Failed to recreate '$ABSOLUTE_TARGET_DIR'."
    exit 1
  fi
else
  echo "[safe_cleanup_dir.sh] Error: Failed to remove '$ABSOLUTE_TARGET_DIR'."
  # Even if rm fails, try to create it, as the goal is to ensure it exists.
  mkdir -p "$ABSOLUTE_TARGET_DIR"
  if [ $? -eq 0 ]; then
    echo "[safe_cleanup_dir.sh] Successfully created '$ABSOLUTE_TARGET_DIR' (even though rm might have failed)."
  else
    echo "[safe_cleanup_dir.sh] Error: Failed to create '$ABSOLUTE_TARGET_DIR' after rm failure."
    exit 1
  fi
fi

exit 0
