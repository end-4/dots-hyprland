state=$(eww get rev_ostg)

if [[ "$state" == "false" ]]; then
    eww open osettings 
    eww update oquery=''
    hyprctl keyword monitor eDP-1, addreserved, 32, 0, 30, -30
    # hyprctl keyword decoration:dim_inactive true
    eww update rev_ostg=true
    sleep 0.3
    wtype -k tab
else
    eww update rev_ostg=false
    hyprctl keyword monitor eDP-1, addreserved, 32, 0, 0, 0
    # hyprctl keyword decoration:dim_inactive false
    sleep 0.3
    eww close osettings 
    eww update oquery=''
fi
