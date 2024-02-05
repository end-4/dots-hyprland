#!/usr/bin/env bash
hyprctl dispatch "$1" $(((($(hyprctl activeworkspace -j | gojq -r .id) - 1)  / 10) * 10 + $2))
