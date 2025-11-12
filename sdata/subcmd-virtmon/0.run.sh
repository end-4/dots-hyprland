# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

readarray -t vmons < <(hyprctl -j monitors all | jq -r '.[] | select(.name | test("^HEADLESS-")) | .name')

ensure_cmds wayvnc lsof jq

if [[ "${CLEAN_VIRTUAL_MONITORS}" = true ]]; then
  echo "Cleaning virtual monitors..."
  for i in "${vmons[@]}"; do
    x hyprctl output remove "$i"
  done
  exit 0
fi
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

echo "Creating tester monitor..."
readarray -t vmons_old < <(hyprctl -j monitors all | jq -r '.[] | select(.name | test("^HEADLESS-")) | .name')
x hyprctl output create headless
readarray -t vmons_new < <(hyprctl -j monitors all | jq -r '.[] | select(.name | test("^HEADLESS-")) | .name')
declare -A seen
for e in "${vmons_old[@]}"; do
  seen["$e"]=1
done
deltas=()
for e in "${vmons_new[@]}"; do
  if [[ -z "${seen[$e]+_}" ]]; then
    deltas+=("$e")
  fi
done
if (( ${#deltas[@]} == 1 )); then
  vmon_tester="${deltas[0]}"
  echo "tester monitor found: $vmons_tester"
elif (( ${#deltas[@]} == 0 )); then
  echo "Error: No tester monitor found"
  exit 1
else
  echo "Error: multiple tester monitor found: ${deltas[*]}"
  exit 1
fi
# TODO: Implement setting geometry
#echo "Setting geometry..."
#${vmon_tester}

echo "Using wayvnc to share monitor $vmons_tester..."
for port in {5900..5999}; do
  if ! lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
    vnc_port="$port"
    break
  fi
done
# TODO: Allow running in background and implement --stop to stop it
if [ -z "$vnc_port" ];then
  echo "No available port for vnc server, aborting..."; exit 1
fi
wayvnc -S -o=${vmon_tester} --log-level=trace 0.0.0.0 $vnc_port

echo "Cleaning the tester monitor..."
hyprctl output remove "${vmon_tester}"
