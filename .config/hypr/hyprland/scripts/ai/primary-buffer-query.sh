#!/usr/bin/env bash

# Default system prompt
SYSTEM_PROMPT="You are a helpful, quick assistant that provides brief and concise explanation \
to given content in at most 100 characters. If the given content is not in English, translate \
it to English. If the content is an English word, provide its meaning. If the content is a name, \
provide some info about it. For a math expression, provide a simplification, \
each step on a line following this style: \`2x=11 (subtract 7 from both sides)\`. \
If you do not know the answer, simply say 'No info available'. \
Only respond for the appropriate case and use as little text as possible.\
The content:"

first_loaded_model=$("$(dirname "$0")/show-loaded-ollama-models.sh" -j | jq -r '.[0].model' 2>/dev/null) || first_loaded_model=""
model=${first_loaded_model:-"llama3.2"}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --model) model="$2"; shift ;; # Set the model from the flag
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Combine the system prompt with the clipboard content
content=$(wl-paste -p | tr '\n' ' ' | head -c 2000)  # 2000 char limit to prevent overflow

# Properly escape content for JSON using jq
prompt_json=$(jq -n --arg system_prompt "$SYSTEM_PROMPT" --arg content "$content" '$system_prompt + " " + $content')

# Make the API call with the specified or default model
api_payload=$(jq -n --arg model "$model" --argjson prompt "$prompt_json" --argjson stream false \
    '{model: $model, prompt: $prompt, stream: $stream}')
response=$(curl -s http://localhost:11434/api/generate -d "$api_payload" | jq -r '.response' 2>/dev/null)

# Check if content is a single line and no longer than 30 characters
if [[ ${#content} -le 30 && "$content" != *$'\n'* ]]; then
    notify-send --app-name="Text selection query" --expire-time=10000 \
        "$content" "$response"
else
    notify-send --app-name="Text selection query" --expire-time=10000 \
        "AI Response" "$response"
fi
