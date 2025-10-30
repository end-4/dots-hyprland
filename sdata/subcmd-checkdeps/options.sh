# Handle args for subcmd: exp-uninstall
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 checkdeps [OPTIONS]...

Experimental unintallation.

Options:
  -h, --help       Show this help message
      --file       A file in plain text containing package names
"
}
# `man getopt` to see more
para=$(getopt \
  -o h \
  -l help,file: \
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
#####################################################################################
## getopt Phase 2

eval set -- "$para"
while true ; do
  case "$1" in
    ## Ones with parameter
    --file)
    if [[ -f "$2" ]];
      then echo "Using list file \"$2\".";LIST_FILE_PATH="$2";shift 2
      else echo "Wrong argument for $1.";exit 1
    fi;;

    ## Ending
    --) break ;;
    *) echo -e "$0: Wrong parameters.";exit 1;;
  esac
done
