#!/usr/bin/env bash

# browser_toggle.sh - Hyprland browser toggler
# Usage: ./browser_toggle.sh <browser-commands...>
# Selects first installed browser from args, focuses existing window,
# checks running process, or launches via hyprctl.

# --- User configuration: browser mappings ---
# Map browser command to its window class (used by hyprctl).
# To add a new browser:
#   1. Find its window class: run 'hyprctl clients' when a window is open,
#      look for the "class" field (e.g., "firefox").
#   2. Add an entry here: ["command-name"]="class-name"
declare -A browser_classes=(
    ["zen-browser"]="zen"
    ["floorp"]="floorp"
    ["waterfox"]="waterfox"
    ["brave"]="brave-browser"
    ["google-chrome-stable"]="google-chrome"
    ["firefox"]="firefox"
    ["microsoft-edge-stable"]="msedge"
    ["vivaldi-stable"]="vivaldi-stable"
    ["librewolf"]="librewolf"
    ["chromium"]="chromium"
    ["opera"]="opera"
    ["helium"]="helium"
)

# Map browser command to its exact process name (used by pgrep -x).
# To add a new browser:
#   1. Find the process name: run 'pgrep -x <name>' or check 'ps aux | grep browser'
#      The name must match exactly (e.g., "firefox", not "firefox-bin").
#   2. Add an entry here: ["command-name"]="process-name"
declare -A browser_procs=(
    ["zen-browser"]="zen-bin"
    ["floorp"]="floorp"
    ["waterfox"]="waterfox-bin"
    ["brave"]="brave"
    ["google-chrome-stable"]="chrome"
    ["firefox"]="firefox"
    ["microsoft-edge-stable"]="msedge"
    ["vivaldi-stable"]="vivaldi-bin"
    ["librewolf"]="librewolf"
    ["chromium"]="chromium"
    ["opera"]="opera"
    ["helium"]="helium"
)

# --- Phase 1: Choose first installed browser from arguments ---
target_cmd=""
for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    if command -v "$cmd" >/dev/null 2>&1; then
        target_cmd="$cmd"
        break
    fi
done
[[ -z "$target_cmd" ]] && exit 1

# Fallback to command name if not in maps
class="${browser_classes[$target_cmd]:-$target_cmd}"
proc="${browser_procs[$target_cmd]:-$target_cmd}"

# --- Phase 2: Single-pass client query (address & workspace) ---
read -r addr ws <<< "$(hyprctl clients -j | jq -r --arg cls "$class" \
    '.[] | select(.class == $cls) | "\(.address) \(.workspace.id)"' | head -n1)"

# If window exists, focus it
if [[ -n "$addr" && "$addr" != "null" ]]; then
    hyprctl dispatch workspace "$ws" >/dev/null
    hyprctl dispatch focuswindow "address:$addr" >/dev/null
    exit 0
fi

# --- Phase 3: If process already running (no window), exit silently ---
if pgrep -x "$proc" >/dev/null; then
    exit 0
fi

# --- Phase 4: Launch browser via Hyprland ---
hyprctl dispatch exec "$target_cmd"
exit 0
