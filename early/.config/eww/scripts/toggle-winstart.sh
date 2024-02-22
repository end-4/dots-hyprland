#!/usr/bin/bash
cd ~/.config/eww || exit
state=$(eww get rev_winstart)

if [[ "$state" == "true" || "$1" == "--close" ]]; then
    scripts/toggle-winpowermenu.sh --close &
    eww update anim_open_winstart=false
    eww update rev_winstart=false
    sleep 0.1
    eww close winstart 2>/dev/null
    eww update winsearch=''
    eww update winsearch_prefix=''
    eww update winstart_allapps=false
    eww update allapps=''
else
    scripts/allapps > scripts/cache/entries.txt &
    scripts/allappnames > scripts/cache/entrynames.txt &
    eww update anim_open_winstart=true
    eww open winstart
    eww update rev_winstart=true
    eww update allapps_get="$(scripts/allapps --mode 2)" &
fi
