#!/usr/bin/bash

if [ "$1" == "--noswitch" ]; then
    imgpath=$(ags run-js 'wallpaper.get(0)')
else
    # Select and set image (hyprland)
    cd "$HOME/Pictures"
    imgpath=$(yad --width 1200 --height 800 --file --title='Choose wallpaper')

    if [ "$imgpath" == '' ]; then
        echo 'Aborted'
        exit 0
    fi

    ags run-js "wallpaper.set('${imgpath}')"
fi

# Generate colors for ags n stuff
"$HOME"/.config/ags/scripts/color_generation/colorgen.sh "${imgpath}" --apply
