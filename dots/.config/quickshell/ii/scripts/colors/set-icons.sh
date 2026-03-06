#!/bin/bash

# Check if a path was provided
# Define the default path
DEFAULT_PATH="$HOME/.local/share/icons/Dynamic"

# Use the first argument if provided, otherwise use the default
ICON_PATH="${1:-$DEFAULT_PATH}"
echo "Icon path: $ICON_PATH"
# Check if the directory actually exists
if [ ! -d "$ICON_PATH" ]; then
    notify-send "Icon Error" "Directory not found: $ICON_PATH"
    echo "Error: Directory $ICON_PATH does not exist."
    exit 1
fi
# Get absolute path and folder name
ICON_SOURCE=$(realpath "$ICON_PATH")
ICON_NAME=$(basename "$ICON_SOURCE")
ICON_DEST="$HOME/.local/share/icons/$ICON_NAME"

# 1. Create the local icons directory if it doesn't exist
mkdir -p "$HOME/.local/share/icons"

# 2. Link the provided path to the system's icon search path
if [ "$ICON_SOURCE" != "$ICON_DEST" ]; then
    echo "Linking $ICON_SOURCE to $ICON_DEST..."
    ln -sfn "$ICON_SOURCE" "$ICON_DEST"
fi

# 3. Apply the theme to KDE configuration
echo "Setting icon theme to: $ICON_NAME"

# This handles both Plasma 5 and Plasma 6
if command -v kwriteconfig6 &> /dev/null; then
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$ICON_NAME"
else
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "$ICON_NAME"
fi

# 4. Force the system to refresh
dbus-send --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0
/usr/bin/perl -e 'use DBus;' &> /dev/null && qdbus org.kde.kded5 /kded org.kde.kded5.reconfigure
