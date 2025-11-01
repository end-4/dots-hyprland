# This script is meant to be sourced, not executed directly.
# shellcheck shell=bash

#####################################################################################

printf "${STY_BLUE}${STY_BOLD}Select execution mode:${STY_RST}\n"
printf "${STY_BLUE}  a = Automatic (no confirmations)  [DEFAULT]\n"
printf "  m = Manual (ask before each command)\n"
printf "  q = Quit${STY_RST}\n"

read -r -p "===> [A/m/q]: " p
case "$p" in
  m|M) ask=true ;;
  q|Q) exit 1 ;;
  *)   ask=false ;; # default: auto
esac

printf "${STY_RST}"
