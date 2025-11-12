# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

readarray -t vmons < <(hyprctl -j monitors all | jq -r '.[] | select(.name | test("^HEADLESS-")) | .name')

if [ "${#vmons[@]}" -gt 0 ]; then
  echo "headless monitors found:"
  printf '%s\n' "${vmons[@]}"
  if [[ ! "${KEEP_VIRTUAL_MONITORS}" = true ]]; then
    echo "Cleaning..."
    for i in "${vmons[@]}"; do
      x hyprctl output remove "$i"
    done
  fi
else
  echo "No headless monitors found."
fi

echo "Creating headless monitor..."
readarray -t vmons_old < <(hyprctl -j monitors all | jq -r '.[] | select(.name | test("^HEADLESS-")) | .name')
x hyprctl output create headless
readarray -t vmons_new < <(hyprctl -j monitors all | jq -r '.[] | select(.name | test("^HEADLESS-")) | .name')
#echo "Setting geometry..."
#${vmon_new}

echo "Using wayvnc to share monitor..."
wayvnc -o=${vmon_new} --log-level=trace 0.0.0.0 5901

echo "Cleaning the new headless monitor..."
x hyprctl output remove "${vmon_new}"
