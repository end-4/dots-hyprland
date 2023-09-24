#!/usr/bin/bash

cd ~/Videos || exit
if [[ "$(pidof wf-recorder)" == "" ]]; then
    notify-send "Starting recording" './recording_'"$(date '+%Y_%m_%_d..%H.%M.%S')"'.mp4' -a 'record-script.sh'
    if [[ "$1" == "--sound" ]]; then
        wf-recorder -t -f './recording_'"$(date '+%Y_%m_%_d..%H.%M.%S')"'.mp4' --geometry "$(slurp)"  --audio=alsa_output.pci-0000_08_00.6.analog-stereo.monitor
    else 
        wf-recorder -t -f './recording_'"$(date '+%Y_%m_%_d..%H.%M.%S')"'.mp4' --geometry "$(slurp)" 
    fi
else
    /usr/bin/kill --signal SIGINT wf-recorder
    notify-send "Recording Stopped" "Stopped" -a 'record-script.sh'
fi
