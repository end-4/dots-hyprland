#!/bin/bash

INTERVAL=2
TOTAL_DURATION=30
SOURCE_TYPE="monitor"  # monitor | input
FIFO=$(mktemp -u /tmp/songrec_out_XXXXXX)

while getopts "i:t:s:" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    t) TOTAL_DURATION=$OPTARG ;;
    s) SOURCE_TYPE=$OPTARG ;;
    *) exit 1 ;;
  esac
done

if ! command -v songrec >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    exit 1
fi

if [ "$SOURCE_TYPE" = "monitor" ]; then
    AUDIO_DEVICE=$(pactl get-default-sink).monitor
elif [ "$SOURCE_TYPE" = "input" ]; then
    AUDIO_DEVICE=$(pactl info | grep "Default Source:" | awk '{print $3}' || true)
else
    echo "Invalid source type"
    exit 1
fi

if [ -z "$AUDIO_DEVICE" ] || ! pactl list short sources | grep -q "$AUDIO_DEVICE"; then
    exit 1
fi

mkfifo "$FIFO"

cleanup() {
    kill "$SONGREC_PID" 2>/dev/null || true
    wait "$SONGREC_PID" 2>/dev/null
    rm -f "$FIFO"
}
trap cleanup EXIT

songrec listen --audio-device "$AUDIO_DEVICE" --request-interval "$INTERVAL" --json --disable-mpris > "$FIFO" &
SONGREC_PID=$!

exec 3< "$FIFO"
SECONDS=0
while (( SECONDS < TOTAL_DURATION )); do
    REMAINING_DURATION=$((TOTAL_DURATION - SECONDS))
    if ! IFS= read -r -t "$REMAINING_DURATION" line <&3; then
        break
    fi
    if printf '%s\n' "$line" | jq -e '
        (.matches | type == "array" and length > 0) and
        (.track.title | type == "string" and length > 0) and
        (.track.subtitle | type == "string" and length > 0) and
        (.track.url | type == "string" and length > 0)
    ' >/dev/null 2>&1; then
        printf '%s\n' "$line"
        exit 0
    fi
done

exit 0
