#!/usr/bin/env bash
for cmd in "$@"; do
    eval "command -v ${cmd%% *}" >/dev/null 2>&1 || continue
    eval "app2unit $cmd" &
    exit
done
exit 1
