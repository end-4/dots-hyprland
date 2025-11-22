# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

ensure_cmds wayvnc lsof jq ip

start_hypr_mon_guard(){
  if ! pgrep -x hypr_mon_guard >/dev/null 2>&1; then
    if PATH=$PATH:${REPO_ROOT}/sdata/subcmd-virtmon command -v hypr_mon_guard ; then
      echo "Running hypr_mon_guard."
      PATH=$PATH:${REPO_ROOT}/sdata/subcmd-virtmon setsid hypr_mon_guard > $(mktemp) 2>&1 &
    else
      echo "Script hypr_mon_guard not found."
      exit 1
    fi
  fi
}
if ! [[ "${DISABLE_HYPR_MON_GUARD}" = true ]]; then
  start_hypr_mon_guard
fi

readarray -t vmon_ids < <(hyprctl -j monitors all | jq -r '.[] | select(.name | test("^TESTER-")) | .name | sub("^TESTER-"; "")')

if [[ "${CLEAN_TESTER_MONITORS}" = true ]]; then
  echo "Cleaning tester monitors..."
  for i in "${vmon_ids[@]}"; do
    echo "Removing tester monitor: TESTER-$i..."
    x hyprctl output remove "TESTER-$i"
  done
  echo "Cleaning tester wayvnc sessions..."
  for i in /tmp/wayvncctl_tester_* ; do
    # When no target is matched, * will not be expanded
    [ -e "$i" ] || continue
    x bash -c "wayvncctl --socket=$i -r wayvnc-exit || rm $i"
  done
  echo "Cleaning complete, exit..."
  exit 0
fi


echo "Finding an unused port..."
for port in {5900..5999}; do
  if ! lsof -nP -iTCP:"$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
    vnc_port="$port"
    break
  fi
done
if [ -z "$vnc_port" ];then
  echo "No available port for vnc server, aborting..."; exit 1
fi
# The name of tester_socket can be anything, the following just borrows $vnc_port as ID
tester_socket=/tmp/wayvncctl_tester_$vnc_port
# In case this exists for some reason
try rm $tester_socket
vmon_tester=TESTER-$vnc_port

echo "Creating tester monitor..."
x hyprctl output create headless ${vmon_tester}

echo "Setting properties of tester monitor..."
x hyprctl keyword monitor ${vmon_tester},${VMON_RESOLUTION}@${VMON_FPS},${VMON_POSITION},${VMON_SCALE}${VMON_EXTRA}

e="%s${STY_RST}\n"
printf "${STY_YELLOW}=========================================$e"
printf "${STY_CYAN}The status of the virtual monitor:$e"
printf "${STY_BLUE}Resolution: ${STY_UNDERLINE}${STY_INVERT}${VMON_RESOLUTION}$e"
printf "${STY_BLUE}Frame rate: ${STY_UNDERLINE}${STY_INVERT}${VMON_FPS}$e"
printf "${STY_CYAN}Use a VNC client to connect to the virtual monitor.$e"
printf "${STY_BLUE}Port: ${STY_UNDERLINE}${STY_INVERT}$vnc_port$e"
printf "${STY_BLUE}IP: use a suitable one from below:$e"
printf ${STY_PURPLE}
LANG=C LC_ALL=C ip -o addr show up | grep -v -E 'docker|veth|virbr' | awk '{split($4,a,"/"); print $2"\t"a[1]}'
printf ${STY_RST}
printf "${STY_CYAN}Hint:$e"
printf "${STY_GREEN}  The VNC client will ask you about server address,$e"
printf "${STY_GREEN}  either joined as <IP>:<Port> or separately.$e"
printf "${STY_GREEN}  As for username and password, just leave them as empty.$e"
printf "${STY_YELLOW}=========================================$e"

if [ "$RUNNING_IN_BACKGROUND" = true ];then
  echo "wayvnc now running in background. Run again with --clean to cleanup."
  nohup wayvnc ${WAYVNC_EX_ARGS} --socket=$tester_socket -f=${VMON_FPS} -o=${vmon_tester} --log-level=${WAYVNC_LOGLEVEL} 0.0.0.0 $vnc_port > $(mktemp) 2>&1 &
  disown
else
  echo "wayvnc now running, press Ctrl-C to quit."
  wayvnc ${WAYVNC_EX_ARGS} --socket=$tester_socket -f=${VMON_FPS} -o=${vmon_tester} --log-level=${WAYVNC_LOGLEVEL} 0.0.0.0 $vnc_port
  echo "wayvnc stopped. Cleaning..."
  hyprctl output remove "${vmon_tester}"
fi
