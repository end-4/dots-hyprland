#!/bin/bash

MONITOR_SOURCE="alsa_output.pci-0000_00_1f.3.analog-stereo.monitor"

# Default değerler
INTERVAL=5
TOTAL_DURATION=30

# Parametreleri oku
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
        echo "Total duration reached. Exiting."
        exit 0
    fi

    TMP_FILE=$(mktemp /tmp/recording.XXXXXX.wav)

    parec --device="$MONITOR_SOURCE" --format=s16le --rate=44100 --channels=2 \
      > >(ffmpeg -f s16le -ar 44100 -ac 2 -i - -t $INTERVAL -acodec libmp3lame "$TMP_FILE" -y -hide_banner -loglevel error) \
      2>/dev/null

    RESULT=$(songrec audio-file-to-recognized-song "$TMP_FILE" 2>/dev/null || true)
    rm -f "$TMP_FILE"

    if [ -n "$RESULT" ] && [ ${#RESULT} -gt 300 ]; then
        echo "$RESULT"
        exit 0
    fi
done
