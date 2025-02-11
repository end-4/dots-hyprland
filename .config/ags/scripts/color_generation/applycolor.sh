#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/ags"
CACHE_DIR="$XDG_CACHE_HOME/ags"
STATE_DIR="$XDG_STATE_HOME/ags"
colormodefile="$STATE_DIR/user/colormode.txt"

if [ ! -d "$CACHE_DIR"/user/generated ]; then
    mkdir -p "$CACHE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

colornames=''
colorstrings=''
colorlist=()
colorvalues=()


# Fetch second line from color mode file
secondline=$(sed -n '2p' "$colormodefile")

# Determine terminal opacity based on the second line
if [[ "$secondline" == *"transparent"* ]]; then # Set for transparent background
    term_transparency=0.83 
    ags_transparency=True
    hypr_opacity=0.9
    hypr_value=1
    rofi_alpha=#00000090
    rofi_alpha_element=#00000025
else #Opaque Stuff
    hypr_value=0
    term_transparency=1
    ags_transparency=False
    hypr_opacity=1
    rofi_alpha="var(surface)"
    rofi_alpha_element="var(surface)"
fi

transparentize() {
  local hex="$1"
  local alpha="$2"
  local red green blue

  red=$((16#${hex:1:2}))
  green=$((16#${hex:3:2}))
  blue=$((16#${hex:5:2}))

  printf 'rgba(%d, %d, %d, %.2f)\n' "$red" "$green" "$blue" "$alpha"
}

get_light_dark() {
    lightdark=""
    if [ ! -f "$STATE_DIR/user/colormode.txt" ]; then
        echo "" > "$STATE_DIR/user/colormode.txt"
    else
        lightdark=$(sed -n '1p' "$STATE_DIR/user/colormode.txt")
    fi
    echo "$lightdark"
}
apply_lightdark() {
    lightdark=$(get_light_dark)
    if [ "$lightdark" = "light" ]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    fi
}

apply_transparency() {
    # Ags
    sed -i "s/$transparent:.*;/$transparent:$ags_transparency;/" ~/.config/ags/scss/mode.scss
    agsv1 run-js "handleStyles(false);"
    # Rofi 
    sed -i "s/wbg:.*;/wbg:$rofi_alpha;/" ~/.config/rofi/config.rasi
    sed -i "s/element-bg:.*;/element-bg:$rofi_alpha_element;/" ~/.config/rofi/config.rasi
    # Hyprland
    sed -i "s/windowrule = opacity .*\ override/windowrule = opacity $hypr_opacity override/" ~/.config/hypr/hyprland/rules/default.conf     
    # Terminal
    sed -i "s/background_opacity  .*\ override/background_opacity  $term_transparency override/" ~/.config/kitty/kitty.conf     
}

colornames=$(cat $STATE_DIR/scss/_material.scss | cut -d: -f1)
colorstrings=$(cat $STATE_DIR/scss/_material.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
colorlist=( $colornames ) # Array of color names
colorvalues=( $colorstrings ) # Array of color values

apply_lightdark &
apply_transparency &
