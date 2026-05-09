#!/usr/bin/env bash
# scratchpad.sh <scratchpad_name>
#
# Launches or toggles a scratchpad (special workspace) for a given app.
# Configuration is read from ~/.config/illogical-impulse/config.json:
#
#   scratchpads.music.enable       (bool)   - enable music scratchpad
#   scratchpads.music.app          (string) - "youtube-music" or "spotify"
#   scratchpads.music.alwaysInSpecial (bool) - skip searching other workspaces
#
#   scratchpads.discord.enable     (bool)   - enable discord scratchpad
#   scratchpads.discord.alwaysInSpecial (bool)
#
# Behavior:
#   - Special workspace visible  → hide it
#   - App open on other workspace → move to special and show
#   - App not open               → launch in special workspace

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_FILE="$XDG_CONFIG_HOME/illogical-impulse/config.json"

SCRATCHPAD_NAME="$1"

cfg() {
    jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null
}

case "$SCRATCHPAD_NAME" in
    music)
        ENABLE=$(cfg '.scratchpads.music.enable // true')
        [ "$ENABLE" = "false" ] && exit 0

        APP=$(cfg '.scratchpads.music.app // "youtube-music"')
        ALWAYS_IN_SPECIAL=$(cfg '.scratchpads.music.alwaysInSpecial // false')

        case "$APP" in
            spotify)
                WINDOW_CLASS="spotify"
                APP_CMD="spotify"
                ;;
            *)
                WINDOW_CLASS="com.github.th_ch.youtube_music"
                APP_CMD="youtube-music"
                ;;
        esac
        ;;
    discord)
        ENABLE=$(cfg '.scratchpads.discord.enable // true')
        [ "$ENABLE" = "false" ] && exit 0

        ALWAYS_IN_SPECIAL=$(cfg '.scratchpads.discord.alwaysInSpecial // false')
        WINDOW_CLASS="discord"
        APP_CMD="discord"
        ;;
    *)
        echo "Usage: scratchpad.sh <music|discord>"
        exit 1
        ;;
esac

# Check if special workspace is visible on any monitor
ACTIVE_SPECIAL=$(hyprctl monitors -j | jq -r '.[].specialWorkspace.name' | grep -Fx "special:$SCRATCHPAD_NAME")

if [ -n "$ACTIVE_SPECIAL" ]; then
    hyprctl dispatch togglespecialworkspace "$SCRATCHPAD_NAME"
    exit 0
fi

# If alwaysInSpecial is true, skip searching other workspaces
if [ "$ALWAYS_IN_SPECIAL" != "true" ]; then
    WINDOW_ADDR=$(hyprctl clients -j | jq -r ".[] | select(.class == \"$WINDOW_CLASS\") | .address" | head -1)
fi

if [ -n "$WINDOW_ADDR" ]; then
    hyprctl dispatch movetoworkspacesilent "special:$SCRATCHPAD_NAME,address:$WINDOW_ADDR"
    hyprctl dispatch togglespecialworkspace "$SCRATCHPAD_NAME"
else
    hyprctl dispatch exec "[workspace special:$SCRATCHPAD_NAME] $APP_CMD"
fi
