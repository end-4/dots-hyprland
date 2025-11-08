#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./gemini-conversation-title.sh <base64_json_input> <output_path>
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <base64_json_input> <output_path>"
    exit 1
fi

BASE64_INPUT="$1"
OUTPUT_PATH="$2"

mkdir -p "$(dirname "$OUTPUT_PATH")"

# decode base64
JSON_INPUT=$(echo "$BASE64_INPUT" | base64 --decode)

MODEL="${GEMINI_MODEL:-gemini-2.0-flash}"
API_KEY=$(secret-tool lookup 'application' 'illogical-impulse' | jq -r '.apiKeys.gemini' 2>/dev/null || echo "")

if [[ -z "$API_KEY" || "$API_KEY" == "null" ]]; then
    echo "Error: Gemini API key not found." >&2
    exit 1
fi

# fetch .rawContents from JSON
CONVO_TEXT=$(echo "$JSON_INPUT" | jq -r '.[].rawContent' | tr '\n' ' ' | sed 's/"/\\"/g')

PROMPT="You are an expert title generation specialist tasked with determining the main topic of a conversation between a user and an AI.
Your job is to analyze the chat transcript and generate a single, short title, consisting of 1 to 6 words, that best summarizes the content.
Constraints: 1. The title must reflect the main theme of the chat. 2. The output must contain only the title text,
and must not include quotation marks, numbers, emojis, explanations, or any extra sentences. 3.
The title must be in the same language as the conversation. 4. Your output must be **only** the title.
Conversation: $CONVO_TEXT"

payload=$(jq -n --arg text "$PROMPT" '{
  contents: [{ parts: [{ text: $text }] }],
  generationConfig: { temperature: 0.2 }
}')

response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent" \
  -H "x-goog-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -X POST \
  -d "$payload")

TITLE=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text' | sed '/^null$/d')

#echo "$TITLE" > "$OUTPUT_PATH"
echo "$TITLE"