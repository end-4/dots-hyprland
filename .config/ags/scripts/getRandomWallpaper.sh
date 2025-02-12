# !/bin/bash
# export SWWW_TRANSITION_FPS=60
# export SWWW_TRANSITION_STEP=2
# export SWWW_TRANSITION_TYPE=grow
# export SWWW_TRANSITION_BEZIER=.43,1.19,1,.4
# export SWWW_TRANSITION_DURATION=1
# export SWWW_TRANSITION_POS=bottom-right

wallpaper=$(find ~/Imagens/Imagens/* -type f | shuf -n1)
swww img "$wallpaper" \
    --transition-bezier .43,1.19,1,.4 \
    --transition-type grow \
    --transition-duration 1 \
    --transition-fps 75 \
    --transition-pos bottom-right
sh $HOME/.config/ags/scripts/color_generation/colorgen.sh "${wallpaper}" --apply --smart;
exit 0
