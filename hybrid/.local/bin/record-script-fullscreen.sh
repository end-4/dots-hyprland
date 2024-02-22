#/usr/bin/bash

cd /home/end/Videos
if ["$(pidof wf-recorder)" -ne ""]; then
    notify-send "wf-recorder" "Starting recording" -a 'wf-recorder'
    wf-recorder -t -f './recording_'"$(date '+%Y_%m_%_d..%H.%M')"'.mp4' --audio=alsa_output.pci-0000_08_00.6.analog-stereo.monitor
else
    /usr/bin/kill --signal SIGINT wf-recorder
    notify-send "wf-recorder" "Recording Stopped" -a 'wf-recorder'
fi
