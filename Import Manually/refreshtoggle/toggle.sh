# Set the default values for the monitor, resolution, and refresh rate
monitor="eDP-1"
resolution="1920x1080"
refresh_rate="60"

while true; do
    charger_status=$(acpi -a | cut -d' ' -f3 | cut -d- -f1)

    if [ "$charger_status" == "off" ]; then
        hyprctl keyword monitor $monitor, ${resolution}@${refresh_rate},0x0,1
    fi

    if [ "$charger_status" == "on" ]; then
        hyprctl keyword monitor $monitor, ${resolution}@144,0x0,1
    fi

    sleep 5
done