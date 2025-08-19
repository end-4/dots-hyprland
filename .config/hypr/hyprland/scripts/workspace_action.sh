curr_workspace="$(hyprctl activeworkspace -j | jq -r ".id")" ##parses json output of hyprctl activeworkspace on the active monitor
dispatcher="$1"
shift ##Any dispatcher that hyprland supports, the shift shifts the target such that target is now in $1, not $2

if [[ -z "${dispatcher}" || "${dispatcher}" == "--help" || "${dispatcher}" == "-h" || -z "$1" ]]; then
  echo "Usage: $0 <dispatcher> <target>"
  exit 1
fi
if [[ "$1" == *"+"* || "$1" == *"-"* ]]; then ##pattern matching (works with r+1 and +1 only aswell)
  hyprctl dispatch "${dispatcher}" "$1" ##$1 = workspace id since we shifted earlier.
elif [[ "$1" =~ ^[0-9]+$ ]]; then ##Regex matching
  target_workspace=$(((($curr_workspace - 1) / 10 ) * 10 + $1))
  hyprctl dispatch "${dispatcher}" "${target_workspace}"
else
 hyprctl dispatch "${dispatcher}" "$1" ##Incase the target in a string, required for special workspaces.
 exit 1
fi
