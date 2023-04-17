#!/usr/bin/bash
currentshader=$(hyprctl getoption decoration:screen_shader -j | gojq -r '.str')

if [[ "$currentshader" == *"nothing.frag" ]]; then
    hyprctl keyword decoration:screen_shader '~/.config/hypr/shaders/extradark.frag'
else
    hyprctl keyword decoration:screen_shader '~/.config/hypr/shaders/nothing.frag'
fi

scripts/hyprsettings tickle