#!/usr/bin/env bash
# TODO: Remove this script (update.sh) after 2025.12.01

STY_RED='\e[31m'
STY_RST='\e[00m'
STY_INVERT='\e[7m'

printf "${STY_RED}"
printf "========================================================================\n"
printf "${STY_INVERT}"
printf "! ATTENTION !"
printf "${STY_RST}\n"
printf "${STY_RED}"
printf "You are using \"./update.sh\" which is kept for compatibility.\n"
printf "Please use \"./setup exp-update-old\" or \"./setup exp-update\" instead.\n"
printf "The old \"./update.sh\" is planned to be removed after 2025.12.01.\n"
printf "========================================================================\n"
printf "${STY_RST}"
sleep 5

cd "$(dirname "$0")"
./setup exp-update-old "$@"
