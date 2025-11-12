# Handle args for subcmd: checkdeps
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 virtmon [OPTIONS]

Create virtual monitor for testing multi-monitors.

Options:
  -h, --help       Show this help message
  -c, --clean      Clean all virtual monitors and exit
  -k, --keep       Do not remove virtual monitors
"
}
# `man getopt` to see more
para=$(getopt \
  -o hck \
  -l help,clean,keep \
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

eval set -- "$para"
while true ; do
  case "$1" in
    -c|--clean) CLEAN_VIRTUAL_MONITORS=true;shift;;
    -k|--keep) KEEP_VIRTUAL_MONITORS=true;shift;;
    --) shift;break ;;
    *) sleep 0 ;;
  esac
done
