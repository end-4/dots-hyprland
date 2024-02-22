#/usr/bin/bash

cd /home/end/Videos
if ["$(pidof wf-recorder)" -ne ""]; then
    rm recording.mp4
    notify-send "wf-recorder" "Starting recording" -a 'wf-recorder'
    wf-recorder --audio=alsa_output.pci-0000_08_00.6.analog-stereo.monitor --geometry "$(slurp)" 
else
    /usr/bin/kill --signal SIGINT wf-recorder
    notify-send "wf-recorder" "Recording Stopped" -a 'wf-recorder'
fi