#/usr/bin/bash

cd /home/end/Videos
if ["$(pidof wf-recorder)" -ne ""]; then
    rm recording.mp4
    notify-send "wf-recorder" "Starting recording"
    wf-recorder --geometry "$(slurp)"
else
    /usr/bin/kill --signal SIGINT wf-recorder
    notify-send "wf-recorder" "Recording Stopped"
fi