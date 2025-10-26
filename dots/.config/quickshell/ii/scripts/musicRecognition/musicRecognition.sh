#!/bin/bash

INTERVAL=5
TOTAL_DURATION=30
MIN_VALID_RESULT_LENGTH=300
SOURCE_TYPE="monitor"  # default | "monitor" : system_sound , "input" : microphone

while getopts "i:t:s:" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    t) TOTAL_DURATION=$OPTARG ;;
    s) SOURCE_TYPE=$OPTARG ;;
    *) echo "Usage: $0 [-i interval_seconds] [-t total_duration_seconds] [-s monitor|input]"
       exit 1 ;;
  esac
done

# Kaynağı belirle
if [ "$SOURCE_TYPE" = "monitor" ]; then
    MONITOR_SOURCE=$(pactl list short sources 2>/dev/null | grep -m1 monitor | awk '{print $2}' || true)
elif [ "$SOURCE_TYPE" = "input" ]; then
    MONITOR_SOURCE=$(pactl info | grep "Default Source:" | awk '{print $3}' || true)
else
    echo "Invalid source type: $SOURCE_TYPE. Use 'monitor' or 'input'."
    exit 1
fi

START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if (( ELAPSED >= TOTAL_DURATION )); then
        echo "Total duration reached, no music recognized."
        exit 0
    fi

    TMP_FILE=$(mktemp /tmp/recording.XXXXXX.wav)

    parec --device="$MONITOR_SOURCE" --format=s16le --rate=44100 --channels=2 \
      > >(ffmpeg -f s16le -ar 44100 -ac 2 -i - -t $INTERVAL -acodec libmp3lame "$TMP_FILE" -y -hide_banner -loglevel error) \
      2>/dev/null

    RESULT=$(songrec audio-file-to-recognized-song "$TMP_FILE" 2>/dev/null || true)
    rm -f "$TMP_FILE"

    if [ -n "$RESULT" ] && [ ${#RESULT} -gt $MIN_VALID_RESULT_LENGTH ]; then
        echo "$RESULT"
        exit 0
    fi
done
