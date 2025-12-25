#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

rm "$XDG_CONFIG_HOME/qt5ct/style-colors.conf"
rm "$XDG_CONFIG_HOME/qt6ct/style-colors.conf"
source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
"$XDG_CONFIG_HOME"/matugen/templates/kde/qt5ct_palette.py > "$XDG_CONFIG_HOME/qt5ct/style-colors.conf"
"$XDG_CONFIG_HOME"/matugen/templates/kde/qt6ct_palette.py > "$XDG_CONFIG_HOME/qt6ct/style-colors.conf"
deactivate
