#!/usr/bin/env bash

getdate() {
    date '+%Y%m%d_%H-%M-%S'
}

cd ~/Videos || exit
if [[ "$(pidof wf-recorder)" == "" ]]; then
    notify-send "Starting recording" 'recording_'"$(getdate)"'.mp4' -a 'record-script.sh'
    if [[ "$1" == "--sound" ]]; then
        wf-recorder -f './recording_'"$(getdate)"'.mp4' -t --geometry "$(slurp)" --audio=alsa_output.pci-0000_08_00.6.analog-stereo.monitor
    elif [[ "$1" == "--fullscreen-sound" ]]; then
        wf-recorder -f './recording_'"$(getdate)"'.mp4' -t --audio=alsa_output.pci-0000_08_00.6.analog-stereo.monitor
    elif [[ "$1" == "--fullscreen" ]]; then
        wf-recorder -f './recording_'"$(getdate)"'.mp4' -t
    else 
        wf-recorder -f './recording_'"$(getdate)"'.mp4' -t --geometry "$(slurp)" 
    fi
else
    /usr/bin/kill --signal SIGINT wf-recorder
    notify-send "Recording Stopped" "Stopped" -a 'record-script.sh'
fi
