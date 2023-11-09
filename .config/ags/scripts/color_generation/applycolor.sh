#!/usr/bin/env bash

cd "$HOME/.config/ags" || exit

# filelist=$(ls 'images/svg/template/' | grep -v /)

# cat scss/_material.scss
colornames=$(cat scss/_material.scss | cut -d: -f1)
colorstrings=$(cat scss/_material.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
# filearr=( $filelist ) # Get colors
colorlist=( $colornames ) # Array of color names
colorvalues=( $colorstrings ) # Array of color values

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
    if [ ! -f ~/.cache/ags/user/colormode.txt ]; then
        echo "" > ~/.cache/ags/user/colormode.txt
    else 
        lightdark=$(cat ~/.cache/ags/user/colormode.txt) # either "" or "-l"
    fi
    echo "$lightdark"
}

# apply_svgs() {
#     for i in "${!filearr[@]}"; do # Loop through folders
#         colorvalue=$(echo "$colorscss" | grep "${filearr[$i]}" | awk '{print $2}' | cut -d ";" -f1)
#         for file in images/svg/template/"${filearr[$i]}"/*; do # Loop through files
#             cp "$file" images/svg/
#             sed -i "s/black/$colorvalue/g" images/svg/"${file##*/}"
#         done
#     done
# }

apply_gtklock() {
    # Check if scripts/templates/gtklock/main.scss exists
    if [ ! -f "scripts/templates/gtklock/main.scss" ]; then
        echo "SCSS not found. Fallback to CSS."
    else
        sassc ~/.config/ags/scripts/templates/gtklock/main.scss ~/.config/gtklock/style.css
        return
    fi
    
    # Check if scripts/templates/gtklock/style.css exists
    if [ ! -f "scripts/templates/gtklock/style.css" ]; then
        echo "Template file not found for Gtklock. Skipping that."
        return
    fi
    # Copy template
    cp "scripts/templates/gtklock/style.css" "$HOME/.config/gtklock/style.css"
    # Apply colors
    for i in "${!colorlist[@]}"; do
        sed -i "s/${colorlist[$i]};/${colorvalues[$i]};/g" "$HOME/.config/gtklock/style.css"
    done
}

apply_fuzzel() {
    # Check if scripts/templates/fuzzel/fuzzel.ini exists
    if [ ! -f "scripts/templates/fuzzel/fuzzel.ini" ]; then
        echo "Template file not found for Fuzzel. Skipping that."
        return
    fi
    # Copy template
    cp "scripts/templates/fuzzel/fuzzel.ini" "$HOME/.config/fuzzel/fuzzel.ini"
    # Apply colors
    for i in "${!colorlist[@]}"; do
        sed -i "s/${colorlist[$i]}ff/${colorvalues[$i]#\#}ff/g" "$HOME/.config/fuzzel/fuzzel.ini"
        sed -i "s/${colorlist[$i]}cc/${colorvalues[$i]#\#}cc/g" "$HOME/.config/fuzzel/fuzzel.ini"
    done
}

apply_foot() {
    # Check if scripts/templates/foot/foot.ini exists
    if [ ! -f "scripts/templates/foot/foot.ini" ]; then
        echo "Template file not found for Foot. Skipping that."
        return
    fi
    # Copy template
    cp "scripts/templates/foot/foot.ini" "$HOME/.config/foot/foot.ini"
    # Apply colors
    for i in "${!colorlist[@]}"; do
        sed -i "s/${colorlist[$i]} #/${colorvalues[$i]#\#}/g" "$HOME/.config/foot/foot.ini" # note: ff because theyre opaque
    done
}

apply_hyprland() {
    # Check if scripts/templates/hypr/colors.conf exists
    if [ ! -f "scripts/templates/hypr/colors.conf" ]; then
        echo "Template file not found for Hyprland colors. Skipping that."
        return
    fi
    # Copy template
    cp "scripts/templates/hypr/colors.conf" "$HOME/.config/hypr/colors.conf"
    # Apply colors
    for i in "${!colorlist[@]}"; do
        sed -i "s/{{ ${colorlist[$i]} }}/${colorvalues[$i]#\#}/g" "$HOME/.config/hypr/colors.conf"
    done
}

apply_gtk() { # Using gradience-cli
    lightdark=$(get_light_dark)

    background=$(cat scss/_material.scss | grep "background" | awk '{print $2}' | cut -d ";" -f1)
    secondaryContainer=$(cat scss/_material.scss | grep "secondaryContainer" | awk '{print $2}' | cut -d ";" -f1)
    
    # Copy template 
    cp "scripts/templates/gradience/preset_template.json" "scripts/templates/gradience/preset.json"

    # Apply colors
    for i in "${!colorlist[@]}"; do
        sed -i "s/{{ ${colorlist[$i]} }}/${colorvalues[$i]}/g" "scripts/templates/gradience/preset.json"
    done

    gradience-cli apply -p scripts/templates/gradience/preset.json --gtk both

    # Set light/dark preference 
    # And set GTK theme manually as Gradience defaults to light adw-gtk3 
    # (which is unreadable when broken when you use dark mode)
    if [ "$lightdark" = "-l" ]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-theme false
        gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-theme true
        gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    fi
}

# apply_svgs
apply_gtklock
apply_fuzzel
apply_foot
apply_hyprland
apply_gtk
