#!/usr/bin/env bash
curr_workspace="$(hyprctl monitors -j | jq -r ".[].activeWorkspace.id")" ##parses json output of hyprctl monitors
dispatcher="$1"; shift ##Any dispatcher that hyprland supports, the shift the arguments such that $2 is not $1
if [[ "$1" == *"+"* || "$1" == *"-"* ]]; then ##pattern matching
  hyprctl dispatch "${dispatcher}" "$1" ##$1 = workspace id since we shifted earlier.
elif [[ "$1" =~ ^[0-9] ]]; then ##Regex matching
  target_workspace=$(((($curr_workspace - 1) / 10 ) * 10 + $1)) ##decreases curr_workspace by 1, then floor division by 10. then multiplica
                                                                ##ion by 10, and then adding $1. for eg, if $curr_workspace=24, and $1 = 6,
                                                                ##((24-1)/10)*10 + 6
                                                                ##(23 / 10) * 10 + 6
                                                                ##2*10+6
                                                                ##26
  hyprctl dispatch "${dispatcher}" "${target_workspace}"
fi
