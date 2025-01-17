# Auto start Hyprland on tty1
if test -z "$DISPLAY" ;and test "$XDG_VTNR" -eq 1
    mkdir -p ~/.cache
    exec Hyprland > ~/.cache/hyprland.log ^&1
end
