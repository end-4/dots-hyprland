state=$(eww get rev_ostg)

if [[ "$state" == "false" ]]; then
    eww open osettings 
    eww update oquery=''
    hyprctl keyword monitor eDP-1, addreserved, 32, 0, 30, -30
    eww update rev_ostg=true
    sleep 0.3
    wtype -k tab
else
    eww update rev_ostg=false
    hyprctl keyword monitor eDP-1, addreserved, 32, 0, 0, 0
    sleep 0.3
    eww close osettings 
    eww update oquery=''
fi
