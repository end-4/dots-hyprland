#!/usr/bin/env bash
# TODO: Handle TAB completion for ./setup with non-intrusive method,
# or other shortcut helper like TUI.
# After that, remove this script (install.sh).


#STY_RED='\e[31m'
#STY_RST='\e[00m'
#printf "${STY_RED}You are using \"./install.sh\" which is kept for compatibility and will be removed in future.\n"
#printf "Please use \"./setup install\" instead.${STY_RST}\n"


cd "$(dirname "$0")"
./setup install "$@"
