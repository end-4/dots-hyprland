#!/usr/bin/env bash
# Based on https://unix.stackexchange.com/a/602935

# Skip if already unlocked
locked_state=$(busctl --user get-property org.freedesktop.secrets \
    /org/freedesktop/secrets/collection/login \
    org.freedesktop.Secret.Collection Locked)    
if [[ "${locked_state}" == "b false" ]]; then
    echo 'Keyring is already unlocked.' >&2
    exit 1
fi

# Prompt for password if not provided
if [[ -z "${UNLOCK_PASSWORD}" ]]; then
    echo -n 'Login password: ' >&2
    read -s UNLOCK_PASSWORD || return
fi

# Unlock
killall -q -u "$(whoami)" gnome-keyring-daemon
eval $(echo -n "${UNLOCK_PASSWORD}" \
           | gnome-keyring-daemon --daemonize --login \
           | sed -e 's/^/export /')
unset UNLOCK_PASSWORD
echo '' >&2
