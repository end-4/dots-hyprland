#!/usr/bin/env bash
for cmd in "$@"; do
    eval "command -v ${cmd%% *}" >/dev/null 2>&1 || continue
    eval "$cmd" &
    exit
done
exit 1
