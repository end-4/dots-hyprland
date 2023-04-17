#!/usr/bin/bash
state=$(eww get winstart_allapps)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    eww update winstart_allapps=false
else
    eww update winstart_allapps=true
    # This sleep is necessary for it to animate smoothly!
    sleep 0.2
    eww update allapps="$(eww get allapps_get)"
fi
