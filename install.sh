#!/usr/bin/env bash
# TODO: Handle TAB completion for ./setup with non-intrusive method
# TODO: Remove this script after TAB completion of ./setup is handled
STY_RED='\e[31m'
STY_RST='\e[00m'
#printf "${STY_RED}You are using \"./install.sh\" which is kept for compatibility and will be removed in future.\n"
#printf "Please use \"./setup install\" instead.${STY_RST}\n"
cd "$(dirname "$0")"
./setup install "$@"
