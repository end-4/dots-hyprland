# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

readarray -t vmon < <(hyprctl -j monitors all | jq -r '.[] | select(.name | test("^HEADLESS-")) | .name')

if [ "${#vmon[@]}" -gt 0 ]; then
  printf '%s\n' "${vmon[@]}"
else
  echo "no headless monitors found" >&2
  exit 1
fi
