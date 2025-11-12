# Handle args for subcmd: checkdeps
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 resetfirstrun [OPTIONS]

Reset firstrun state.

Options:
  -h, --help       Show this help message and exit
"
}
# `man getopt` to see more
para=$(getopt \
  -o c \
  -l help \
  -n "$0" -- "$@")
[ $? != 0 ] && echo "$0: Error when getopt, please recheck parameters." && exit 1
#####################################################################################
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    --) shift;break ;;
    *) sleep 0 ;;
  esac
done
