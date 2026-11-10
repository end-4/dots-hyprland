#!/usr/bin/env bash
# sleep-inhibit-toggle.sh
# Toggle a system-wide sleep/idle inhibitor (the bar's "stay awake" toggle).
#
# Implemented with a detached `systemd-inhibit ... sleep infinity` process that holds a
# logind BLOCK lock for:
#   sleep              -> systemctl/loginctl suspend is refused (no auto or manual suspend)
#   idle               -> hypridle honours systemd idle inhibitors (ignore_systemd_inhibit
#                         defaults to false), so its listeners pause: no lock at 5 min, no
#                         dpms off at 10 min, no suspend at 90 min
#   handle-lid-switch  -> closing the lid does not suspend
# Releasing = killing that process; the kernel/logind drops the lock immediately. Nothing is
# configured permanently, so a crash or logout can never leave sleep disabled forever.
#
# State lives in XDG_RUNTIME_DIR (wiped on logout) -> no stale "on" after a reboot:
#   sleep-inhibit.pid    PID of the running systemd-inhibit process
#   sleep-inhibit.state  "on" | "off" — watched by the bar widget (SleepInhibitToggle.qml)
#
# Usage: sleep-inhibit-toggle.sh {status|toggle|on|off}
#   status -> prints "on" or "off"

set -uo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
PID_FILE="$STATE_DIR/sleep-inhibit.pid"
STATE_FILE="$STATE_DIR/sleep-inhibit.state"

WHAT="sleep:idle:handle-lid-switch"
WHO="Quickshell bar"
# Unique marker: lets us find/kill a stray inhibitor whose PID file was lost.
WHY="stay awake (quickshell-sleep-inhibit)"

# --- helpers -----------------------------------------------------------------

write_state() {
    printf '%s\n' "$1" >"$STATE_FILE"
}

# Finds a stray inhibitor by marker when the PID file is gone. Scans ONLY processes actually
# named `systemd-inhibit` and greps /proc/<pid>/cmdline — deliberately NOT `pkill -f marker`,
# which also matches any shell/editor whose command line merely mentions the marker string
# (that footgun killed the test shell once).
find_inhibitor() {
    local pid cmdline
    for pid in $(pgrep -x systemd-inhibit 2>/dev/null); do
        cmdline="$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null)"
        case "$cmdline" in
        *quickshell-sleep-inhibit*)
            printf '%s' "$pid"
            return 0
            ;;
        esac
    done
    return 1
}

# Prints the live inhibitor PID (and returns 0) when one is running, else returns 1.
running_pid() {
    local pid=""
    if [ -f "$PID_FILE" ]; then
        pid="$(cat "$PID_FILE" 2>/dev/null)"
    fi
    # Fall back to the marker when the PID file is missing/stale (e.g. killed by hand).
    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
        pid="$(find_inhibitor)" || return 1
    fi
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null || return 1
    printf '%s' "$pid"
}

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a "Sleep" -i "$2" -t 2000 "$1" "$3" >/dev/null 2>&1 || true
}

# --- actions -----------------------------------------------------------------

inhibit_on() {
    if running_pid >/dev/null; then
        write_state on
        return 0
    fi
    # Detached from this script: it must outlive the toggle AND survive a Quickshell reload.
    systemd-inhibit --what="$WHAT" --who="$WHO" --why="$WHY" --mode=block \
        sleep infinity </dev/null >/dev/null 2>&1 &
    local pid=$!
    disown "$pid" 2>/dev/null || true
    # Give logind a moment, then confirm the lock really exists before claiming success.
    sleep 0.3
    if ! kill -0 "$pid" 2>/dev/null; then
        write_state off
        notify "Stay awake" "dialog-error" "Could not take the sleep inhibitor"
        return 1
    fi
    printf '%s\n' "$pid" >"$PID_FILE"
    write_state on
    notify "Staying awake" "preferences-desktop-screensaver" "The screen stays on and the system won't sleep"
}

inhibit_off() {
    local pid
    if pid="$(running_pid)"; then
        # `pkill -P` (by parent PID) reaps the forked `sleep infinity` without the
        # cmdline-matching footgun; kill the inhibitor itself afterwards so the lock drops.
        pkill -P "$pid" 2>/dev/null
        kill "$pid" 2>/dev/null
    fi
    rm -f "$PID_FILE"
    write_state off
    notify "Sleep allowed" "preferences-desktop-screensaver" "Normal sleep and screen timers are back"
}

status() {
    if running_pid >/dev/null; then
        write_state on
        echo on
    else
        # Self-heal: drop a stale PID file so the widget never shows a phantom "on".
        rm -f "$PID_FILE"
        write_state off
        echo off
    fi
}

case "${1:-status}" in
status) status ;;
on) inhibit_on ;;
off) inhibit_off ;;
toggle)
    if running_pid >/dev/null; then inhibit_off; else inhibit_on; fi
    ;;
*)
    echo "usage: $(basename "$0") {status|toggle|on|off}" >&2
    exit 2
    ;;
esac
