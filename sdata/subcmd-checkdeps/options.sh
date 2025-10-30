# Handle args for subcmd: checkdeps
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 checkdeps [OPTIONS] <LIST_FILE_PATH>...

Check whether pkgs listed in <LIST_FILE_PATH> exist in AUR or repos of Arch.

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
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    --) shift;break ;;
    *) sleep 0 ;;
  esac
done

if [[ -f "$1" ]]; then
  echo "Using list file \"$1\".";LIST_FILE_PATH="$1";shift 1
else
  echo "Wrong path \"$1\" of list file.";exit 1
fi
