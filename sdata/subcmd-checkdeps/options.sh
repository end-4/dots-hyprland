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

if [[ -f "$1" ]]; then
  echo "Using list file \"$1\".";LIST_FILE_PATH="$1";shift 2
else
  echo "Wrong path of list file.";exit 1
fi
