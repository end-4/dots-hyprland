#!/bin/bash

rootDir=$1
mountPoint=$2

unlock() {
    i=0
    while :; do
        ! encfs --extpass=/usr/lib/seahorse/ssh-askpass "$rootDir" "$mountPoint" || break
        i=$((i + 1))
        [[ $i -lt 3 ]] || exit 1
    done
}
# foot zsh -c "source ~/.zshrc && yazi $mountPoint"

fusermount -u "$mountPoint" || (unlock && nautilus $mountPoint)
