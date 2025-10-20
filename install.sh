#!/usr/bin/env bash
# Remove this script (install.sh) after 2025.12.01

STY_RED='\e[31m'
STY_RST='\e[00m'
printf "${STY_RED}You are using \"./install.sh\" which is kept for compatibility and will be removed in future.\n"
printf "Please use \"./setup install\" instead.${STY_RST}\n"

cd "$(dirname "$0")"
./setup install "$@"
