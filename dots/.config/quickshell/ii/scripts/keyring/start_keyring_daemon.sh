#!/usr/bin/env bash
# Start a secrets service daemon if one isn't already available on D-Bus.
# Supports gnome-keyring-daemon out of the box, but users can override
# by setting KEYRING_DAEMON_CMD in their Hyprland env config, e.g.:
#   env = KEYRING_DAEMON_CMD, keepassxc --minimized
#
# If the org.freedesktop.secrets D-Bus service is already registered
# (e.g. KeePassXC is configured as a D-Bus service), this script exits
# early and does nothing.

# Check if a secrets service is already available on D-Bus
if busctl --user list 2>/dev/null | grep -q 'org.freedesktop.secrets'; then
    echo "Secrets service already available on D-Bus, skipping daemon start." >&2
    exit 0
fi

if [[ -n "${KEYRING_DAEMON_CMD}" ]]; then
    echo "Starting custom keyring daemon: ${KEYRING_DAEMON_CMD}" >&2
    exec ${KEYRING_DAEMON_CMD}
elif command -v gnome-keyring-daemon &>/dev/null; then
    echo "Starting gnome-keyring-daemon" >&2
    exec gnome-keyring-daemon --start --components=secrets
else
    echo "Warning: No secrets service found. Install gnome-keyring or set KEYRING_DAEMON_CMD." >&2
    exit 1
fi
