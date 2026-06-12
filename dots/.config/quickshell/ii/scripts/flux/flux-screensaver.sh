#!/bin/bash

PIDFILE="/tmp/flux-screensaver.pid"
ACTIVEFILE="/tmp/flux-screensaver-active"

if [ "$1" = "--resume" ]; then
  # Handled by the temporary watcher now.
  exit 0
fi

if pgrep -x flux-desktop >/dev/null; then
  exit 0
fi

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
IDLE_TIMEOUT=180

if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
  ENABLED=$(jq -r '.screensaver.enable // false' "$CONFIG_FILE")
  [ "$ENABLED" = "false" ] && exit 0
  IDLE_TIMEOUT=$(jq -r '.screensaver.idleTimeout // 180' "$CONFIG_FILE")
fi

REMAINING=$(( IDLE_TIMEOUT - 10 ))
[ "$REMAINING" -lt 0 ] && REMAINING=0
sleep "$REMAINING"

FLUX_SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/flux-screensaver"
mkdir -p "$FLUX_SETTINGS_DIR"
jq '.screensaver + {"seed": "1337"}' "$CONFIG_FILE" > "$FLUX_SETTINGS_DIR/settings.json" 2>/dev/null || true
export FLUX_CONFIG="$FLUX_SETTINGS_DIR/settings.json"

# Run flux-desktop in the background
"${XDG_BIN_HOME:-$HOME/.local/bin}/flux-desktop" &
FLUX_PID=$!

# Wait for the window to map and trigger the inevitable fake activity
sleep 3

# Start a temporary hypridle to watch for REAL user activity
WATCHER_CONF="/tmp/flux-watcher.conf"
cat << EOF > "$WATCHER_CONF"
general {
    ignore_dbus_inhibit = true
}
listener {
    timeout = 1
    on-timeout = true
    on-resume = pkill -P $$ flux-desktop 2>/dev/null || pkill flux-desktop 2>/dev/null
}
EOF

hypridle -c "$WATCHER_CONF" &
WATCHER_PID=$!

# Cleanup trap
trap 'kill $WATCHER_PID 2>/dev/null; kill $FLUX_PID 2>/dev/null; rm -f "$WATCHER_CONF"; exit' TERM INT

wait $FLUX_PID
kill $WATCHER_PID 2>/dev/null
rm -f "$WATCHER_CONF"