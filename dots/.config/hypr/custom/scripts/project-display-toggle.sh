#!/usr/bin/env bash
# Toggle Project Display QuickShell Sidebar
if pkill -f "qs -p .*ProjectDisplay.qml"; then
    exit 0
fi
exec qs -p "$HOME/.config/hypr/custom/scripts/ProjectDisplay.qml"
