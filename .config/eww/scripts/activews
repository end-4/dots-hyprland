#!/usr/bin/bash

hyprctl activeworkspace -j | gojq '.id'

if [ "$1" == "--once" ]; then
  exit 0
else
  socat -u UNIX-CONNECT:/tmp/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock - | rg --line-buffered "workspace>>" | while read -r line; do
    case ${line%>>*} in
      "workspace")
        focusedws=${line#*>>}
        echo "$focusedws"
        ;;
    esac  
  done
fi

