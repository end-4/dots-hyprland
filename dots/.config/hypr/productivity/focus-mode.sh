#!/usr/bin/env bash
# Focus Mode - Temporarily blocks distracting applications
# Usage: focus-mode.sh [enable|disable|toggle|status]

FOCUS_MODE_STATE_FILE="$HOME/.cache/hypr/focus-mode-state"
FOCUS_MODE_CONFIG="$HOME/.config/hypr/productivity/focus-mode.conf"
BLOCKED_WINDOWS_FILE="$HOME/.cache/hypr/focus-mode-blocked-windows"

# Create cache directory if it doesn't exist
mkdir -p "$HOME/.cache/hypr"

# Default blocked applications (can be overridden in focus-mode.conf)
DEFAULT_BLOCKED_APPS=(
    "steam"
    "discord"
    "spotify"
    "youtube"
    "reddit"
    "twitter"
    "facebook"
    "instagram"
    "tiktok"
    "netflix"
    "twitch"
)

# Load custom configuration if exists
if [[ -f "$FOCUS_MODE_CONFIG" ]]; then
    source "$FOCUS_MODE_CONFIG"
    # Use BLOCKED_APPS from config if defined, otherwise use default
    BLOCKED_APPS="${BLOCKED_APPS[@]:-${DEFAULT_BLOCKED_APPS[@]}}"
else
    BLOCKED_APPS=("${DEFAULT_BLOCKED_APPS[@]}")
fi

# Function to check if focus mode is enabled
is_enabled() {
    [[ -f "$FOCUS_MODE_STATE_FILE" ]] && [[ "$(cat "$FOCUS_MODE_STATE_FILE")" == "enabled" ]]
}

# Function to enable focus mode
enable_focus_mode() {
    echo "enabled" > "$FOCUS_MODE_STATE_FILE"
    
    # Store currently running blocked apps
    > "$BLOCKED_WINDOWS_FILE"
    
    # Close/minimize blocked applications
    for app in "${BLOCKED_APPS[@]}"; do
        # Get all windows matching the app
        hyprctl clients -j | jq -r ".[] | select(.class | ascii_downcase | contains(\"$app\")) | .address" | while read -r addr; do
            if [[ -n "$addr" ]]; then
                echo "$addr|$app" >> "$BLOCKED_WINDOWS_FILE"
                # Close the window
                hyprctl dispatch closewindow "address:$addr"
            fi
        done
        
        # Kill any running processes
        pkill -fi "$app" 2>/dev/null || true
    done
    
    # Add window rules to block new windows
    for app in "${BLOCKED_APPS[@]}"; do
        hyprctl keyword windowrule "workspace special:blocked silent,class:.*${app}.*" -i
        hyprctl keyword windowrule "nofocus,class:.*${app}.*" -i
    done
    
    # Send notification
    notify-send -a "Focus Mode" -i "emblem-important" "Focus Mode Enabled" "Distracting applications have been blocked. Stay focused! 🎯"
    
    # Update QuickShell if available
    qs -c ii ipc call focusModeUpdate enabled 2>/dev/null || true
}

# Function to disable focus mode
disable_focus_mode() {
    # Remove window rules
    if [[ -f "$BLOCKED_WINDOWS_FILE" ]]; then
        for app in "${BLOCKED_APPS[@]}"; do
            hyprctl keyword windowrule "unset,class:.*${app}.*" -i 2>/dev/null || true
        done
        rm -f "$BLOCKED_WINDOWS_FILE"
    fi
    
    echo "disabled" > "$FOCUS_MODE_STATE_FILE"
    
    # Send notification
    notify-send -a "Focus Mode" -i "emblem-default" "Focus Mode Disabled" "You can now access all applications again."
    
    # Update QuickShell if available
    qs -c ii ipc call focusModeUpdate disabled 2>/dev/null || true
}

# Function to toggle focus mode
toggle_focus_mode() {
    if is_enabled; then
        disable_focus_mode
    else
        enable_focus_mode
    fi
}

# Function to show status
show_status() {
    if is_enabled; then
        echo "Focus Mode: ENABLED"
        echo "Blocked applications:"
        printf '%s\n' "${BLOCKED_APPS[@]}"
    else
        echo "Focus Mode: DISABLED"
    fi
}

# Main logic
case "${1:-toggle}" in
    enable)
        enable_focus_mode
        ;;
    disable)
        disable_focus_mode
        ;;
    toggle)
        toggle_focus_mode
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 [enable|disable|toggle|status]"
        exit 1
        ;;
esac
