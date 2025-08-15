#!/bin/bash
##This script is kinda an improvement for the workspace_action script of end4. This script allows for relative workspace keybind. The next and prev workspaces allow for relative-
##Workspace support, using the second arg. while the first arg is "ch" or "mv"

##Example Usage: bash workspace_action ch next

curr_workspace="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .activeWorkspace.name')"
next_workspace="$(echo $curr_workspace +1 | bc)" 
prev_workspace="$(echo $curr_workspace -1 | bc)"

if [ "$1" == "ch" ]; then
  if [ "$2" == "next" ]; then
    hyprctl dispatch workspace $next_workspace
  elif [ "$2" == "prev" ]; then
    hyprctl dispatch workspace $prev_workspace
  else 
    hyprctl dispatch workspace $2
  fi 
elif [ "$1" == "mv" ]; then
   if [ "$2" == "next" ]; then
    hyprctl dispatch movetoworkspace $next_workspace
   elif [ "$2" == "prev" ]; then
    hyprctl dispatch movetoworkspace $prev_workspace
   else 
    hyprctl dispatch movetoworkspace $2
   fi 
else
  echo "Valid Options are: mv and ch"
fi
