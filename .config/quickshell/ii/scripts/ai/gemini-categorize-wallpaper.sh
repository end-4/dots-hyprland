#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "Usage: $0 <image_path>"
    exit 1
fi

SOURCE_IMG_PATH="$1"
WALLPAPER_NAME="$(basename "$SOURCE_IMG_PATH")"
RESIZED_IMG_PATH="/tmp/quickshell/ai/wallpaper.jpg"
magick "$SOURCE_IMG_PATH" -resize 200x -quality 50 "$RESIZED_IMG_PATH"
API_KEY=$(secret-tool lookup 'application' 'illogical-impulse' | jq -r '.apiKeys.gemini')

if [[ "$(base64 --version 2>&1)" = *"FreeBSD"* ]]; then
B64FLAGS="--input"
else
B64FLAGS="-w0"
fi

payload='{
    "contents": [{
    "parts":[
        {
            "inline_data": {
            "mime_type":"image/jpeg",
            "data": "'"$(base64 $B64FLAGS $RESIZED_IMG_PATH)"'"
            }
        },
        {"text": "Categorize the wallpaper. Its file name is '"$WALLPAPER_NAME"'"}
    ]
    }],
    "generationConfig": {
        "responseMimeType": "text/x.enum",
        "responseSchema": {
            "type": "string",
            "enum": [ "abstract", "anime", "city", "minimalist", "landscape", "plants", "person", "space" ]
        },
        "temperature": 0,
    }
}'
# echo "$payload" | jq
response=$(curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent" \
-H "x-goog-api-key: $API_KEY" \
-H 'Content-Type: application/json' \
-X POST \
-d "$payload" 2> /dev/null)

echo "$response" | jq -r '.candidates[0].content.parts[0].text'
