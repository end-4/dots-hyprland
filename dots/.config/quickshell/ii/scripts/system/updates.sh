#!/bin/bash

if [ -e /etc/arch-release ]; then # Arch Linux
    updates=$(checkupdates-with-aur | wc -l)
elif [ -e /etc/fedora-release ]; then # Fedora Linux
    updates=$(dnf check-update -q|grep -c ^[a-z0-9])
else
    updates=0
fi

echo -n "$updates"
