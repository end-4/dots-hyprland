#!/bin/bash

# wrapper script for other installation scripts

USAGE="usage: instantutils [action]
    root              execute postinstall steps for root owned files
    user              execute postinstall steps for user owned files
    repo              add instantOS repos to the system
    alttab            launch alttab with instantOS theming
    default           create symlinks for default applications
    open              open default application \$2
    dotfiles          restore deleted default dotfiles
    conky             launch conky with instantOS tooltips
    rangerplugins     install instantOS ranger plugins
    help              show this message"

if [ -z "$1" ]; then
    echo "$USAGE"
    exit
fi

case "$1" in
root)
    sudo /usr/share/instantutils/rootinstall.sh
    ;;
default)
    /usr/share/instantutils/setup/defaultapps
    ;;
alttab)
    alttab -fg "#ffffff" -bg "#121212" -frame "#89B3F7" -d 0 -s 1 -t 128x150 -i 127x64 -w 1 -vp pointer &
    ;;
user)
    /usr/share/instantutils/userinstall.sh
    ;;
repo)
    /usr/share/instantutils/repo.sh
    ;;
open)
    if [ -z "$2" ]; then
        echo "usage: instantutils open defaultappname"
        exit
    fi
    if ! [ -e ~/.config/instantos/default/"$2" ]; then
        instantutils default
        chmod +x ~/.config/instantos/default/"$2"
    fi
    APP="$2"
    shift 2
    ~/.config/instantos/default/"$APP" "$@"
    ;;
dotfiles)
    imosid apply /usr/share/instantdotfiles/dotfiles
    ;;
rangerplugins)
    cd || exit 1
    mkdir instantos &>/dev/null
    echo "installing ranger plugins"
    mkdir -p ~/.config/ranger/plugins
    cp -r /usr/share/rangerplugins/* ~/.config/ranger/plugins/
    if [ "$2" = '-f' ]
    then
        cat /usr/share/instantdotfiles/dotfiles/ranger/commands.py > ~/.config/ranger/commands.py
        cat /usr/share/instantdotfiles/dotfiles/ranger/rc.conf > ~/.config/ranger/rc.conf
    fi
    ;;
conky)
    shuf /usr/share/instantwidgets/tooltips.txt | head -1 >~/.cache/tooltip
    conky -c /usr/share/instantwidgets/tooltips.conf &
    ;;

hide)
    /usr/share/instantutils/setup/hideapps
    ;;
*)
    echo "$USAGE"
    ;;
esac
