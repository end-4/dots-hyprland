#!/bin/bash
# startup-apps.sh — Launch apps into specific Hyprland workspaces on login
# Zen Browser → workspace 1, Teams PWA → workspace 2, Code → workspace 3+
#
# For Code: each new window opens in the next workspace (3, 4, 5, ...).
# Uses hyprctl dispatch rules to place windows before they open.

DELAY_BETWEEN=1.5  # Seconds between app launches (let windows settle)

log() { echo "[startup-apps] $*"; }

wait_for_hyprland() {
    for i in $(seq 1 10); do
        hyprctl monitors &>/dev/null && return 0
        sleep 1
    done
    log "ERROR: Hyprland not ready"
    return 1
}

# Launch an app on a specific workspace using Hyprland dispatch rules
launch_on_workspace() {
    local ws="$1"
    shift
    local class="$1"
    shift

    # Set a one-shot window rule to place the next window of this class on the target workspace
    hyprctl dispatch -- exec "[workspace ${ws} silent]" "$@"
}

wait_for_hyprland || exit 1

# Give the desktop a moment to settle after login
sleep 2

# ── Workspace 1: Zen Browser ──
log "Launching Zen Browser → workspace 1"
launch_on_workspace 1 "zen-beta" zen-browser
sleep "$DELAY_BETWEEN"

# ── Workspace 2: Microsoft Teams PWA (Chromium) ──
log "Launching Teams PWA → workspace 2"
launch_on_workspace 2 "crx_cifhbcnohmdccbgoicgdjpfamggdegmo" \
    /usr/bin/chromium --profile-directory=Default --app-id=cifhbcnohmdccbgoicgdjpfamggdegmo
sleep "$DELAY_BETWEEN"

# ── Workspace 3+: VS Code windows ──
# Code often restores multiple windows from previous session.
# We use workspace rules to spread them across workspaces 3, 4, 5, ...
log "Launching VS Code → workspace 3+"

# Set up rules to spread Code windows across workspaces starting at 3
# These are one-shot rules that apply to each new window in order
NEXT_WS=3
MAX_CODE_WS=8  # Don't go beyond workspace 8

# Pre-set rules for Code windows
for ws in $(seq "$NEXT_WS" "$MAX_CODE_WS"); do
    hyprctl keyword windowrulev2 "workspace ${ws} silent, class:^(code-url-handler)$, onworkspace:0" 2>/dev/null
done

# Launch Code (it will restore previous session windows)
hyprctl dispatch -- exec "[workspace 3 silent]" code
sleep 3

# After Code has had time to open its windows, remove the dynamic rules
# and apply a smarter approach: move each Code window to sequential workspaces
CODE_WINDOWS=$(hyprctl clients -j 2>/dev/null | python3 -c "
import json, sys
clients = json.load(sys.stdin)
code_windows = [c for c in clients if c.get('class') == 'code-url-handler']
for w in code_windows:
    print(w['address'])
" 2>/dev/null)

if [ -n "$CODE_WINDOWS" ]; then
    ws=$NEXT_WS
    while IFS= read -r addr; do
        if [ "$ws" -le "$MAX_CODE_WS" ]; then
            log "Moving Code window $addr → workspace $ws"
            hyprctl dispatch movetoworkspacesilent "$ws,address:$addr" 2>/dev/null
            ws=$((ws + 1))
        fi
    done <<< "$CODE_WINDOWS"
fi

# Switch to workspace 1 so you start on the browser
sleep 0.5
hyprctl dispatch workspace 1

log "Startup apps launched."
