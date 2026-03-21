#!/usr/bin/env bash

DEFAULT_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
CONFIG_FILE="$DEFAULT_CONFIG"
JSON_PATH=".screenRecord"

# Allow override via --config argument (parse before reading config)
for ((i=1; i<=$#; i++)); do
    if [[ "${!i}" == "--config" && $((i+1)) -le $# ]]; then
        CONFIG_FILE="${!((i+1))}"
        break
    fi
done

CUSTOM_PATH=$(jq -r "$JSON_PATH.savePath" "$CONFIG_FILE" 2>/dev/null)
RECORD_DESKTOP_AUDIO=$(jq -r "$JSON_PATH.recordDesktopAudio // true" "$CONFIG_FILE" 2>/dev/null)
RECORD_MIC_AUDIO=$(jq -r "$JSON_PATH.recordMicAudio // false" "$CONFIG_FILE" 2>/dev/null)
DESKTOP_AUDIO_SOURCE=$(jq -r "$JSON_PATH.desktopAudioSource // \"\"" "$CONFIG_FILE" 2>/dev/null)
MIC_AUDIO_SOURCE=$(jq -r "$JSON_PATH.micAudioSource // \"\"" "$CONFIG_FILE" 2>/dev/null)

RECORDING_DIR=""

if [[ -n "$CUSTOM_PATH" && "$CUSTOM_PATH" != "null" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos"
fi

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}

# Get desktop/output audio source for gpu-screen-recorder
# GSR uses: default_output, default_input, or device:<pactl_name>
getaudiooutput() {
    if [[ -n "$DESKTOP_AUDIO_SOURCE" && "$DESKTOP_AUDIO_SOURCE" != "null" ]]; then
        echo "device:$DESKTOP_AUDIO_SOURCE"
    else
        echo "default_output"
    fi
}

getaudioinput() {
    if [[ -n "$MIC_AUDIO_SOURCE" && "$MIC_AUDIO_SOURCE" != "null" ]]; then
        echo "device:$MIC_AUDIO_SOURCE"
    else
        echo "default_input"
    fi
}

# Build -a args for gpu-screen-recorder based on config toggles
# GSR -a can be specified multiple times; combine with | for multiple sources
build_audio_args() {
    local sources=()
    if [[ "$RECORD_DESKTOP_AUDIO" == "true" ]]; then
        sources+=("$(getaudiooutput)")
    fi
    if [[ "$RECORD_MIC_AUDIO" == "true" ]]; then
        sources+=("$(getaudioinput)")
    fi
    if [[ ${#sources[@]} -eq 0 ]]; then
        return
    fi
    # Combine with | as GSR supports: default_output|default_input
    printf -v combined '%s|' "${sources[@]}"
    echo "${combined%|}"
}

getactivemonitor() {
    local name
    name=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name')
    if [[ -n "$name" && "$name" != "null" ]]; then
        echo "$name"
    else
        echo "screen"
    fi
}

# Convert quickshell region format to GSR format
# Quickshell/ScreenshotAction: "x,y widthxheight" (e.g. "100,200 640x480")
# GSR -region: "widthxheight+x+y" (e.g. "640x480+100+200")
to_gsr_region() {
    local region="$1"
    if [[ "$region" =~ ^([0-9]+),([0-9]+)[[:space:]]+([0-9]+)x([0-9]+)$ ]]; then
        echo "${BASH_REMATCH[3]}x${BASH_REMATCH[4]}+${BASH_REMATCH[1]}+${BASH_REMATCH[2]}"
    else
        echo "$region"
    fi
}

mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
FULLSCREEN_FLAG=0
for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' & disown
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    fi
done

# Use config-driven audio by default.
# --sound is kept for compatibility with existing call sites, but audio no longer depends on it.
INCLUDE_AUDIO=0
if [[ "$RECORD_DESKTOP_AUDIO" == "true" || "$RECORD_MIC_AUDIO" == "true" || $SOUND_FLAG -eq 1 ]]; then
    INCLUDE_AUDIO=1
fi

# Only stop our own recording (no -r); leave replay/streaming alone and start recording alongside it
OUR_RECORDING_PID=""
while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    cmdline=$(cat "/proc/$pid/cmdline" 2>/dev/null | tr '\0' ' ')
    # Replay/streaming has -r; our recording does not
    if [[ ! "$cmdline" =~ (^|[[:space:]])-r([[:space:]]|$|[0-9]) ]]; then
        OUR_RECORDING_PID=$pid
        break
    fi
done < <(pgrep -f "gpu-screen-recorder")

if [[ -n "$OUR_RECORDING_PID" ]]; then
    kill -SIGINT "$OUR_RECORDING_PID"
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
else
    RECORDING_FILE="recording_$(getdate).mp4"
    notify-send "Starting recording" "$RECORDING_FILE" -a 'Recorder' & disown

    GSR_ARGS=()
    if [[ $INCLUDE_AUDIO -eq 1 ]]; then
        AUDIO_SOURCE=$(build_audio_args)
        [[ -z "$AUDIO_SOURCE" ]] && AUDIO_SOURCE="default_output"
        GSR_ARGS+=("-a" "$AUDIO_SOURCE")
    fi
    GSR_ARGS+=("-o" "./$RECORDING_FILE")

    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        MONITOR=$(getactivemonitor)
        exec gpu-screen-recorder "${GSR_ARGS[@]}" -w "$MONITOR"
    else
        if [[ -n "$MANUAL_REGION" ]]; then
            # From quickshell region selector: "x,y widthxheight"
            GSR_REGION=$(to_gsr_region "$MANUAL_REGION")
        else
            # Interactive slurp: use GSR-compatible format WxH+X+Y
            if ! GSR_REGION=$(slurp -f "%wx%h+%x+%y" 2>&1); then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
                exit 1
            fi
        fi
        # Pass -a -o before -w so audio is correctly applied to region capture
        exec gpu-screen-recorder "${GSR_ARGS[@]}" -w "$GSR_REGION"
    fi
fi
