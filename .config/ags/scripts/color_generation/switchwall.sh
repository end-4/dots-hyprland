#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_DIR="$XDG_CONFIG_HOME/ags"

if [ "$1" == "--noswitch" ]; then
    imgpath=$(swww query | head -1 | awk -F 'image: ' '{print $2}')
    # imgpath=$(ags run-js 'wallpaper.get(0)')
else
    # Select and set image (hyprland)
    cd "$(xdg-user-dir PICTURES)"
    imgpath=$(yad --width 1200 --height 800 --file --title='Choose wallpaper' --add-preview --large-preview)
    read scale screenx screeny screensizey < <(hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
    cursorposx=$(hyprctl cursorpos -j | gojq '.x' 2>/dev/null) || cursorposx=960
    cursorposx=$(bc <<< "scale=0; ($cursorposx - $screenx) * $scale / 1")
    cursorposy=$(hyprctl cursorpos -j | gojq '.y' 2>/dev/null) || cursorposy=540
    cursorposy=$(bc <<< "scale=0; ($cursorposy - $screeny) * $scale / 1")
    cursorposy_inverted=$(( screensizey - cursorposy ))

    if [ "$imgpath" == '' ]; then
        echo 'Aborted'
        exit 0
    fi


    # ags run-js "wallpaper.set('')"
    # sleep 0.1 && ags run-js "wallpaper.set('${imgpath}')" &
    swww img "$imgpath" --transition-step 100 --transition-fps 60 \
    --transition-type grow --transition-angle 30 --transition-duration 1 \
    --transition-pos "$cursorposx, $cursorposy_inverted"
fi

# Generate colors for ags n stuff
"$CONFIG_DIR"/scripts/color_generation/colorgen.sh "${imgpath}" --apply --smart
