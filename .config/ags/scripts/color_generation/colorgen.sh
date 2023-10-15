#!/usr/bin/bash

# check if no arguments
if [ $# -eq 0 ]; then
    echo "Usage: colorgen.sh /path/to/image (--apply)"
    exit 1
fi

# check if the file ~/.cache/ags/user/colormode.txt exists. if not, create it. else, read it to $lightdark
lightdark=""
if [ ! -f "$HOME/.cache/ags/user/colormode.txt" ]; then
    echo "" > "$HOME/.cache/ags/user/colormode.txt"
else 
    lightdark=$(cat "$HOME/.cache/ags/user/colormode.txt") # either "" or "-l"
fi
# check if the file ~/.cache/ags/user/colorbackend.txt exists. if not, create it. else, read it to $lightdark
backend="material"
if [ ! -f "$HOME/.cache/ags/user/colorbackend.txt" ]; then
    echo "material" > "$HOME/.cache/ags/user/colorbackend.txt"
else 
    backend=$(cat "$HOME/.cache/ags/user/colorbackend.txt") # either "" or "-l"
fi

cd "$HOME/.config/ags/scripts/" || exit
if [ "$backend" = "material" ]; then
    color_generation/generate_colors_material.py --path "$1" "$lightdark" > $HOME/.cache/ags/user/generated_colors.txt
    if [ "$2" = "--apply" ]; then
        cp $HOME/.cache/ags/user/generated_colors.txt "$HOME/.config/ags/scss/_material.scss"
        color_generation/applycolor.sh
    fi
elif [ "$backend" = "pywal" ]; then
    # clear and generate
    wal -c
    echo wal -i "$1" -n -t -s -e "$lightdark" -q 
    wal -i "$1" -n -t -s -e $lightdark -q 
    # copy scss
    cp "$HOME/.cache/wal/colors.scss" $HOME/.cache/ags/user/generated_colors.txt
    
    cat color_generation/pywal_to_material.scss >> $HOME/.cache/ags/user/generated_colors.txt
    if [ "$2" = "--apply" ]; then
        sassc $HOME/.cache/ags/user/generated_colors.txt $HOME/.cache/ags/user/generated_colors_classes.scss --style compact
        sed -i "s/ { color//g" $HOME/.cache/ags/user/generated_colors_classes.scss
        sed -i "s/\./$/g" $HOME/.cache/ags/user/generated_colors_classes.scss
        sed -i "s/}//g" $HOME/.cache/ags/user/generated_colors_classes.scss
        if [ "$lightdark" = "-l" ]; then
            printf "\n"'$darkmode: false;'"\n" >> $HOME/.cache/ags/user/generated_colors_classes.scss
        else
            printf "\n"'$darkmode: true;'"\n" >> $HOME/.cache/ags/user/generated_colors_classes.scss
        fi

        cp $HOME/.cache/ags/user/generated_colors_classes.scss "$HOME/.config/ags/scss/_material.scss"

        color_generation/applycolor.sh
    fi
fi
