#!/usr/bin/bash

screenwidth=$(hyprctl monitors -j | gojq -r '.[0]["width"]')
screenheight=$(hyprctl monitors -j | gojq -r '.[0]["height"]')
framerate=$(qalc "ceil("$(hyprctl monitors -j | gojq -r '.[0]["refreshRate"]')")" | cut -d= -f2 | tr -d ' ')
monitor=$(hyprctl monitors -j | gojq -r '.[0]["name"]')

hyprctl keyword monitor "$monitor",addreserved,"$1","$2","$3","$4"