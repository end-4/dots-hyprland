#!/usr/bin/env bash
# Based on https://unix.stackexchange.com/a/602935
# Unlocks the keyring via the freedesktop secrets D-Bus API.
# Only restarts gnome-keyring-daemon if it is the active secrets provider.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Skip if already unlocked
if "${SCRIPT_DIR}/is_unlocked.sh"; then
    exit 1
fi

# Prompt for password if not provided
if [[ -z "${UNLOCK_PASSWORD}" ]]; then
    echo -n 'Login password: ' >&2
    read -s UNLOCK_PASSWORD || return
fi

# Check which secrets provider is running
secrets_owner=$(busctl --user get-property org.freedesktop.secrets \
    /org/freedesktop/secrets org.freedesktop.DBus.Peer GetMachineId 2>/dev/null)

# Only use the gnome-keyring-daemon unlock flow if it's the active provider
if pgrep -u "$(whoami)" -f gnome-keyring-daemon &>/dev/null; then
    killall -q -u "$(whoami)" gnome-keyring-daemon
    eval $(echo -n "${UNLOCK_PASSWORD}" \
               | gnome-keyring-daemon --daemonize --login \
               | sed -e 's/^/export /')
else
    # For non-gnome-keyring providers (e.g. KeePassXC), attempt unlock via
    # the freedesktop secrets D-Bus API
    echo -n "${UNLOCK_PASSWORD}" | busctl --user call org.freedesktop.secrets \
        /org/freedesktop/secrets/collection/login \
        org.freedesktop.Secret.Collection Unlock 's' '' 2>/dev/null \
        || echo "Note: Keyring unlock via D-Bus not supported by your provider. Unlock it manually." >&2
fi

unset UNLOCK_PASSWORD
echo '' >&2
