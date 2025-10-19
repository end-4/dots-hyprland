# Handle args for subcmd: exp-uninstall
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 exp-uninstall [OPTIONS]...

Experimental unintallation.

Options:
  -h, --help       Show this help message
"
}
# `man getopt` to see more
para=$(getopt \
  -o h \
  -l help \
  -n "$0" -- "$@")
[ $? != 0 ] && echo "$0: Error when getopt, please recheck parameters." && exit 1
#####################################################################################
## getopt Phase 1
# ignore parameter's order, execute options below first
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    --) break ;;
    *) shift ;;
  esac
done
