#!/bin/bash

PIDFILE="/tmp/flux-screensaver.pid"
ACTIVEFILE="/tmp/flux-screensaver-active"

if [ "$1" = "--resume" ]; then
  if [ -f "$ACTIVEFILE" ]; then
    AGE=$(($(date +%s) - $(stat -c %Y "$ACTIVEFILE" 2>/dev/null || echo 0)))
    if [ "$AGE" -gt 2 ]; then
      kill $(cat "$PIDFILE" 2>/dev/null) 2>/dev/null
      rm -f "$PIDFILE" "$ACTIVEFILE"
      pkill flux-desktop 2>/dev/null
    fi
  else
    kill $(cat "$PIDFILE" 2>/dev/null) 2>/dev/null
    rm -f "$PIDFILE" "$ACTIVEFILE"
    pkill flux-desktop 2>/dev/null
  fi
  exit 0
fi

if pgrep -x flux-desktop >/dev/null; then
  exit 0
fi

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/ii/config.json"
IDLE_TIMEOUT=180

if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
  ENABLED=$(jq -r '.screensaver.enable // false' "$CONFIG_FILE")
  [ "$ENABLED" = "false" ] && exit 0
  IDLE_TIMEOUT=$(jq -r '.screensaver.idleTimeout // 180' "$CONFIG_FILE")
fi

echo $$ > "$PIDFILE"
rm -f "$ACTIVEFILE"

SLEEP_PID=""
trap 'rm -f "$PIDFILE" "$ACTIVEFILE"; [ -n "$SLEEP_PID" ] && kill $SLEEP_PID 2>/dev/null; pkill flux-desktop 2>/dev/null; exit' TERM INT

sleep "$IDLE_TIMEOUT" &
SLEEP_PID=$!
wait $SLEEP_PID 2>/dev/null

touch "$ACTIVEFILE"

FLUX_SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/flux-screensaver"
mkdir -p "$FLUX_SETTINGS_DIR"
jq '.screensaver + {"seed": "1337"}' "$CONFIG_FILE" > "$FLUX_SETTINGS_DIR/settings.json" 2>/dev/null || true
export FLUX_CONFIG="$FLUX_SETTINGS_DIR/settings.json"
exec "${XDG_BIN_HOME:-$HOME/.local/bin}/flux-desktop"
