#!/bin/bash

INTERVAL=2
TOTAL_DURATION=30
MIN_VALID_RESULT_LENGTH=300
SOURCE_TYPE="monitor"  # monitor | input
TMP_RAW="/tmp/songrec_recording.raw"
TMP_MP3="/tmp/songrec_recording.mp3"

while getopts "i:t:s:" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    t) TOTAL_DURATION=$OPTARG ;;
    s) SOURCE_TYPE=$OPTARG ;;
    *) exit 1 ;;
  esac
done
if [ "$SOURCE_TYPE" = "monitor" ]; then
    MONITOR_SOURCE=$(pactl list short sources 2>/dev/null | grep -m1 monitor | awk '{print $2}' || true)
elif [ "$SOURCE_TYPE" = "input" ]; then
    MONITOR_SOURCE=$(pactl info | grep "Default Source:" | awk '{print $3}' || true)
else
    exit 1
fi

if [ -z "$MONITOR_SOURCE" ]; then
    exit 1
fi

cleanup() {
    rm -f "$TMP_RAW" "$TMP_MP3"
    pkill -P $$ parec >/dev/null 2>&1 || true
}
trap cleanup EXIT

parec --device="$MONITOR_SOURCE" --format=s16le --rate=44100 --channels=2 > "$TMP_RAW" &
START_TIME=$(date +%s)

while true; do
    sleep "$INTERVAL"
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if (( ELAPSED >= TOTAL_DURATION )); then
        exit 0
    fi

    ffmpeg -f s16le -ar 44100 -ac 2 -i "$TMP_RAW" -acodec libmp3lame -y -hide_banner -loglevel error "$TMP_MP3" 2>/dev/null

    RESULT=$(songrec audio-file-to-recognized-song "$TMP_MP3" 2>/dev/null || true)

    if echo "$RESULT" | grep -q '"matches": \[' && [ ${#RESULT} -gt $MIN_VALID_RESULT_LENGTH ]; then
        echo "$RESULT"
        exit 0
    fi
done
