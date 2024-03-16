#!/usr/bin/env bash


# check if no arguments
if [ $# -eq 0 ]; then
    echo "Usage: colorgen.sh /path/to/image (--apply)"
    exit 1
fi

# check if the file ~/.cache/ags/user/colormode.txt exists. if not, create it. else, read it to $lightdark
lightdark="dark"
transparency="opaque"
materialscheme="tonalspot"
if [ ! -f "$HOME/.cache/ags/user/colormode.txt" ]; then
    echo "dark\nopaque\ntonalspot" > "$HOME/.cache/ags/user/colormode.txt"
else
    lightdark=$(sed -n '1p' "$HOME/.cache/ags/user/colormode.txt")
    transparency=$(sed -n '2p' "$HOME/.cache/ags/user/colormode.txt")
    materialscheme=$(sed -n '3p' "$HOME/.cache/ags/user/colormode.txt")
fi
backend="material" # color generator backend
if [ ! -f "$HOME/.cache/ags/user/colorbackend.txt" ]; then
    echo "material" > "$HOME/.cache/ags/user/colorbackend.txt"
else
    backend=$(cat "$HOME/.cache/ags/user/colorbackend.txt") # either "" or "-l"
fi

cd "$HOME/.config/ags/scripts/" || exit
if [[ "$1" = "#"* ]]; then # this is a color
    source ${HOME}/virtualenvs/my_project_venv/bin/activate
    color_generation/generate_colors_material.py --color "$1" --mode "$lightdark" --scheme "$materialscheme" --transparency "$transparency" > "$HOME"/.cache/ags/user/generated/material_colors.scss
    deactivate
    if [ "$2" = "--apply" ]; then
        cp "$HOME"/.cache/ags/user/generated/material_colors.scss "$HOME/.config/ags/scss/_material.scss"
        color_generation/applycolor.sh
    fi
elif [ "$backend" = "material" ]; then
    source ${HOME}/virtualenvs/my_project_venv/bin/activate
    color_generation/generate_colors_material.py --path "$1" --mode "$lightdark" --scheme "$materialscheme" --transparency "$transparency" > "$HOME"/.cache/ags/user/generated/material_colors.scss
    deactivate
    if [ "$2" = "--apply" ]; then
        cp "$HOME"/.cache/ags/user/generated/material_colors.scss "$HOME/.config/ags/scss/_material.scss"
        color_generation/applycolor.sh
    fi
elif [ "$backend" = "pywal" ]; then
    # clear and generate
    wal -c
    wal -i "$1" -n $lightdark -q
    # copy scss
    cp "$HOME/.cache/wal/colors.scss" "$HOME"/.cache/ags/user/generated/material_colors.scss

    cat color_generation/pywal_to_material.scss >> "$HOME"/.cache/ags/user/generated/material_colors.scss
    if [ "$2" = "--apply" ]; then
        sass "$HOME"/.cache/ags/user/generated/material_colors.scss "$HOME"/.cache/ags/user/generated/colors_classes.scss --style compact
        sed -i "s/ { color//g" "$HOME"/.cache/ags/user/generated/colors_classes.scss
        sed -i "s/\./$/g" "$HOME"/.cache/ags/user/generated/colors_classes.scss
        sed -i "s/}//g" "$HOME"/.cache/ags/user/generated/colors_classes.scss
        if [ "$lightdark" = "-l" ]; then
            printf "\n""\$darkmode: false;""\n" >> "$HOME"/.cache/ags/user/generated/colors_classes.scss
        else
            printf "\n""\$darkmode: true;""\n" >> "$HOME"/.cache/ags/user/generated/colors_classes.scss
        fi

        cp "$HOME"/.cache/ags/user/generated/colors_classes.scss "$HOME/.config/ags/scss/_material.scss"

        color_generation/applycolor.sh
    fi
fi
