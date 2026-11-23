#!/usr/bin/env bash
# audio-mono-toggle.sh
# Toggle the PipeWire default output between normal stereo and a runtime mono downmix.
#
# Mono is implemented with a temporary `pw-loopback` virtual sink (node.name=mono_sink):
#   - The sink has a single MONO channel, so apps writing stereo are summed (L+R) into it.
#   - The loopback fans that mono channel back out to BOTH channels of whatever output was
#     the default at toggle time, so every speaker plays the same summed signal.
# Turning mono off kills the loopback and restores the previous default sink. Nothing
# persists across reboots and no permanent device clutters the mixer.
#
# Usage: audio-mono-toggle.sh {status|toggle|on|off}
#   status -> prints "mono" or "stereo"

MONO_NODE="mono_sink"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
PREV_SINK_FILE="$STATE_DIR/mono-toggle.prev-sink"
PID_FILE="$STATE_DIR/mono-toggle.pid"

# --- helpers -----------------------------------------------------------------

mono_active() {
    # Source of truth: does our mono sink node currently exist?
    pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -qx "$MONO_NODE"
}

sink_exists() {
    pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -qx "$1"
}

# Move every app stream to $1, EXCEPT our own loopback playback stream (skipping it
# avoids a feedback loop: loopback output -> mono sink -> loopback -> ...).
move_streams() {
    local target="$1" cur="" skip=0 line
    while IFS= read -r line; do
        if [[ "$line" == "Sink Input #"* ]]; then
            [ -n "$cur" ] && [ "$skip" -eq 0 ] && pactl move-sink-input "$cur" "$target" 2>/dev/null
            cur="${line#Sink Input #}"
            skip=0
        elif [[ "$line" == *pw-loopback* || "$line" == *"$MONO_NODE"* ]]; then
            skip=1
        fi
    done < <(pactl list sink-inputs 2>/dev/null)
    [ -n "$cur" ] && [ "$skip" -eq 0 ] && pactl move-sink-input "$cur" "$target" 2>/dev/null
    return 0
}

kill_loopback() {
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
    fi
    # Fallback in case the pid file was lost: match only the pw-loopback process that
    # carries our node name (kept specific so it can't match unrelated commands).
    pkill -f "pw-loopback.*node\.name=$MONO_NODE" 2>/dev/null
    return 0
}

# --- actions -----------------------------------------------------------------

enable_mono() {
    mono_active && return 0

    local real
    real="$(pactl get-default-sink 2>/dev/null)"
    [ -z "$real" ] && return 1
    [ "$real" = "$MONO_NODE" ] && return 0
    echo "$real" > "$PREV_SINK_FILE"

    pw-loopback \
        --capture-props="media.class=Audio/Sink node.name=$MONO_NODE node.description=Mono audio.position=[MONO]" \
        --playback-props="target.object=$real" \
        >/dev/null 2>&1 &
    echo $! > "$PID_FILE"

    # Wait (up to ~3s) for the virtual sink to register.
    local i
    for ((i = 0; i < 60; i++)); do
        sink_exists "$MONO_NODE" && break
        sleep 0.05
    done
    if ! sink_exists "$MONO_NODE"; then
        kill_loopback
        rm -f "$PREV_SINK_FILE"
        return 1
    fi

    pactl set-default-sink "$MONO_NODE"
    move_streams "$MONO_NODE"
}

disable_mono() {
    if ! mono_active; then
        kill_loopback
        rm -f "$PID_FILE" "$PREV_SINK_FILE"
        return 0
    fi

    local prev=""
    [ -f "$PREV_SINK_FILE" ] && prev="$(cat "$PREV_SINK_FILE")"
    # If the remembered sink is gone (e.g. unplugged), fall back to the first real sink.
    if [ -z "$prev" ] || ! sink_exists "$prev"; then
        prev="$(pactl list short sinks 2>/dev/null | awk -v m="$MONO_NODE" '$2 != m {print $2; exit}')"
    fi

    if [ -n "$prev" ]; then
        pactl set-default-sink "$prev"
        move_streams "$prev"
    fi
    kill_loopback
    rm -f "$PID_FILE" "$PREV_SINK_FILE"
}

# --- entry -------------------------------------------------------------------

case "${1:-status}" in
    status)        mono_active && echo mono || echo stereo ;;
    toggle)        mono_active && disable_mono || enable_mono ;;
    on | enable)   enable_mono ;;
    off | disable) disable_mono ;;
    *) echo "usage: $0 {status|toggle|on|off}" >&2; exit 1 ;;
esac
