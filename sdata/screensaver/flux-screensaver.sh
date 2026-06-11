#!/usr/bin/env bash
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
PIDFILE="/tmp/flux-screensaver.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  exit 0
fi
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"; pkill flux-desktop 2>/dev/null; exit' TERM INT

IDLE_TIMEOUT=180
if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
  ENABLED=$(jq -r '.screensaver.enable // false' "$CONFIG_FILE")
  [ "$ENABLED" = "false" ] && { rm -f "$PIDFILE"; exit 0; }
  IDLE_TIMEOUT=$(jq -r '.screensaver.idleTimeout // 180' "$CONFIG_FILE")
fi

sleep "$IDLE_TIMEOUT"

FLUX_SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/flux-screensaver"
mkdir -p "$FLUX_SETTINGS_DIR"
jq '.screensaver + {"seed": "1337"}' "$CONFIG_FILE" > "$FLUX_SETTINGS_DIR/settings.json" 2>/dev/null || true
export FLUX_CONFIG="$FLUX_SETTINGS_DIR/settings.json"
exec "${XDG_BIN_HOME:-$HOME/.local/bin}/flux-desktop"
