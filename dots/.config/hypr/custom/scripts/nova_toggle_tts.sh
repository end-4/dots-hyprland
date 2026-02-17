#!/usr/bin/env bash
# Toggle nova TTS voice responses on/off via REST API
# Shows a desktop notification with the new state

TOKEN_FILE="$HOME/.config/nova/api_token"
API="http://127.0.0.1:9876/api/v1"

if [[ ! -f "$TOKEN_FILE" ]]; then
    notify-send -h string:suppress-sound:true -a "Nova" "Nova is not running" -i nova-npu -u critical
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

RESPONSE=$(curl -sf -X POST "$API/toggle_tts" \
    -H "Authorization: Bearer $TOKEN" 2>&1)

if [[ $? -ne 0 ]]; then
    notify-send -h string:suppress-sound:true -a "Nova" "Nova is not running" -i nova-npu -u critical
    exit 1
fi

# Parse the tts_enabled field from JSON response
ENABLED=$(echo "$RESPONSE" | grep -o '"tts_enabled":\s*\(true\|false\)' | grep -o 'true\|false')

if [[ "$ENABLED" == "true" ]]; then
    notify-send -h string:suppress-sound:true -a "Nova" "TTS ON 🔊" -i nova-npu
else
    notify-send -h string:suppress-sound:true -a "Nova" "TTS OFF 🔇" -i nova-npu
fi
