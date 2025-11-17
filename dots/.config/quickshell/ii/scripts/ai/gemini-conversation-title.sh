#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./gemini-conversation-title.sh <base64_json_input>

BASE64_INPUT="$1"
#JSON_INPUT="$1"

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

PROMPT="You are helping to automatically name and tag a chat based on its content.
Analyze the conversation text and respond with a concise, meaningful title and a fitting Material Symbols icon name.

Rules:
- Respond only in valid JSON.
- The JSON must contain two fields: "title" and "icon".
- "title" should be a short, human-readable summary (short but very informative) of the chat topic (maximum 4-5 words).
- "icon" must be one of the names from Google’s official Material Symbols icon set (for example: "lightbulb", "chat", "code", "backpack", "psychology", "build", "explore", etc.).
- The icon name must be lowercase and must exist in the Material Symbols library.
- Use the conversation's language when naming the title.
- Do not include any explanations, Markdown, or text outside of the JSON object.
- Do not include any additional text.
- Do not use any capital letters except for the first letter of the first word
- When choosing an icon, don't shy away from thinking abstractly. For example, a lightbulb for something like new ideas
Conversation:
$CONVO_TEXT"

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

echo "$TITLE"