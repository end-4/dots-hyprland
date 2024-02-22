#!/usr/bin/bash
cd ~/.config/eww
reserves=$(hyprctl monitors -j | gojq -r -c '.[0]["reserved"]')
state=$(eww get osd_vol)

closewinvol() {
    eww update osd_vol=false
    sleep 0.2
    eww close winosd_vol 2>/dev/null
}
closewinosd() {
    eww update osd_bright=false
    sleep 0.2
    eww close winosd_bright 2>/dev/null
}
openwinosd() {
    if [ "$state" = "true" ]; then
        closewinvol
    fi
    eww open winosd_bright
    eww update osd_bright=true
}
closeosd() {
    eww update osd_bright=false
    sleep 0.2
    eww close osd 2>/dev/null
}
openosd() {
    eww open osd
    eww update osd_bright=true
}

if [ "$reserves" = "[0,0,0,50]" ]; then # windoes mode active
    eww close osd 2>/dev/null &
    if [[ "$1" == "--open" ]]; then
        openwinosd
    else
        closewinosd
    fi
    exit 0
fi

eww close winosd_vol 2>/dev/null &
eww close winosd_bright 2>/dev/null &
if [[ "$1" == "--open" ]]; then 
    openosd
elif [[ "$1" == "--close" ]]; then
    closeosd
else
    closeosd
fi
