# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

ensure_cmds wayvnc lsof jq ip

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

echo "Setting geometry..."
x hyprctl keyword monitor ${vmon_tester},${VMON_RESOLUTION}@${VMON_FPS},${VMON_POSITION},${VMON_SCALE}${VMON_EXTRA}

e="%s${STY_RST}\n"
printf "${STY_CYAN}$e" "========================================="
printf "${STY_BLUE}$e" "Use a VNC client to connect to the virtual monitor."
printf "${STY_RED}$e" "  Port: $vnc_port"
printf "${STY_RED}$e" "  IP: choose a suitable one from below:"
LANG=C LC_ALL=C ip -o addr show up | grep -v -E 'docker|veth|virbr' | awk '{split($4,a,"/"); print $2"\t"a[1]}'
printf "${STY_YELLOW}$e" "The status of the virtual monitor:"
printf "${STY_YELLOW}$e" "  Resolution: ${VMON_RESOLUTION}"
printf "${STY_YELLOW}$e" "  Frame rate: ${VMON_FPS}"
printf "${STY_GREEN}$e" "Hint:"
printf "${STY_GREEN}$e" "  The VNC client will ask you about server address,"
printf "${STY_GREEN}$e" "  either joined as <IP>:<Port> or separately."
printf "${STY_GREEN}$e" "  As for username and password, just leave them as empty."
printf "${STY_CYAN}$e" "========================================="

if [ "$RUNNING_IN_BACKGROUND" = true ];then
  echo "wayvnc now running in background. Run again with --clean to cleanup."
  nohup wayvnc --socket=$tester_socket -f=${VMON_FPS} -o=${vmon_tester} --log-level=${WAYVNC_LOGLEVEL} 0.0.0.0 $vnc_port > $(mktemp) 2>&1 &
  disown
else
  echo "wayvnc now running, press Ctrl-C to quit."
  wayvnc --socket=$tester_socket -f=${VMON_FPS} -o=${vmon_tester} --log-level=${WAYVNC_LOGLEVEL} 0.0.0.0 $vnc_port
  echo "wayvnc stopped. Cleaning..."
  hyprctl output remove "${vmon_tester}"
fi
