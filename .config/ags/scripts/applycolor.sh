#!/usr/bin/env bash

cd "$HOME/.config/ags" || exit


# filelist=$(ls 'images/svg/template/' | grep -v /)
# colorscss=$(cat css/_material.scss)
colornames=$(cat scss/_material.scss | cut -d: -f1)
colorstrings=$(cat scss/_material.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
# filearr=( $filelist ) # Get colors
colorlist=( $colornames ) # Array of color names
colorvalues=( $colorstrings ) # Array of color values

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
        sed -i "s/${colorlist[$i]}ff/${colorvalues[$i]#\#}ff/g" "$HOME/.config/fuzzel/fuzzel.ini" # note: ff because theyre opaque
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
        sed -i "s/=${colorlist[$i]} #/=${colorvalues[$i]#\#}/g" "$HOME/.config/foot/foot.ini" # note: ff because theyre opaque
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
        sed -i "s/(${colorlist[$i]}/(${colorvalues[$i]#\#}/g" "$HOME/.config/hypr/colors.conf" # note: ff because theyre opaque
    done
}

# apply_svgs
apply_gtklock
apply_fuzzel
apply_foot
apply_hyprland
