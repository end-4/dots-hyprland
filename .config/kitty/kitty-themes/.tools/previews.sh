#!/bin/bash
# @author: @vrdhn on github

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" >/dev/null 2>&1 && pwd  )"
cd $SCRIPT_DIR/..

set_theme () {
    cat themes/$1.conf | awk 'BEGIN {printf("kitty @ set-colors ")} {printf( "%s=%s ",$1,$2 )} END{printf("\n")}' | sh
}

list=$(find themes -type f | grep "$1" |  xargs basename | cut -d. -f1)

for x in $list ;
do
    kitty +kitten icat "previews/$x.png"
    read -n 1 -p "$x   : Next / Set / Quit :" ans
    echo

    case $ans in
        n ) ;;
        s )  set_theme $x ; exit ;;
        q ) exit ;;
    esac
done
