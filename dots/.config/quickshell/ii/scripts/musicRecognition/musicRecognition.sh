#!/bin/bash

## can be added manually if not chosen automatically with running this on terminal 'pw-cli list-objects | grep node.name' and manually choose the one you want.
MONITOR_SOURCE=$(pactl list short sources 2>/dev/null | grep -m1 monitor | awk '{print $2}' || true)

INTERVAL=5
TOTAL_DURATION=30
MIN_VALID_RESULT_LENGTH=300 

while getopts "i:t:" opt; do
  case $opt in
    i) INTERVAL=$OPTARG ;;
    t) TOTAL_DURATION=$OPTARG ;;
    *) echo "Usage: $0 [-i interval_seconds] [-t total_duration_seconds]"
       exit 1 ;;
  esac
done

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
