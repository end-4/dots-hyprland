# Handle args for subcmd: checkdeps
# shellcheck shell=bash

VMON_RESOLUTION=1920x1080
VMON_FPS=60
VMON_POSITION=auto
VMON_SCALE=1
VMON_EXTRA=""
WAYVNC_LOGLEVEL=${WAYVNC_LOGLEVEL:-quiet}

showhelp(){
echo -e "Syntax: $0 virtmon [OPTIONS]

Create virtual monitor for testing multi-monitors.

Note:
  The virtual monitor will be served via wayvnc.
  You need a VNC client to connect to it.

Options:
  -h, --help       Show this help message and exit
  -c, --clean      Clean all tester monitors and wayvnc sessions and exit

  -d, --daemon     Running in background
      --res <res>  Resolution, by default $VMON_RESOLUTION
      --fps <fps>  Refresh rate and FPS, by default $VMON_FPS
      --pos <pos>  Position, by default $VMON_POSITION
      --sca <sca>  Scale, by default $VMON_SCALE
      --ext <ext>  Extra args, e.g. \"transform, 1\"
"
}
# `man getopt` to see more
para=$(getopt \
  -o hcd \
  -l help,clean,daemon,res:,fps:,pos:,sca:,ext: \
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
    -c|--clean) CLEAN_TESTER_MONITORS=true;shift;;
    -d|--daemon) RUNNING_IN_BACKGROUND=true;shift;;
    --res) VMON_RESOLUTION="$2";shift 2;;
    --fps) VMON_FPS="$2";shift 2;;
    --pos) VMON_POSITION="$2";shift 2;;
    --sca) VMON_SCALE="$2";shift 2;;
    --ext) VMON_EXTRA=", $2";shift 2;;
    --) shift;break ;;
    *) sleep 0 ;;
  esac
done
