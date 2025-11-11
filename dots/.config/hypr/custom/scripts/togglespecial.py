#!/bin/python

import json
import os
import subprocess

active_window_json = subprocess.run(
    ["hyprctl", "-j", "activewindow"], capture_output=True, text=True
)
active_window = json.loads(active_window_json.stdout)
# subprocess.run(["notify-send", active_window_json.stdout])

sw_file = "/tmp/specialworkspace"
if active_window and "special" in active_window["workspace"]["name"]:
    subprocess.run(["hyprctl", "dispatch togglespecialworkspace dummy"])
    subprocess.run(["hyprctl", "dispatch togglespecialworkspace dummy"])

    with open(sw_file, "w+") as specialworkspace:
        specialworkspace.write(active_window["workspace"]["name"].split(":")[1])

else:
    if os.path.isfile(sw_file):
        with open(sw_file, "r") as specialworkspace:
            sw = specialworkspace.read()
            subprocess.run(
                [
                    "hyprctl",
                    f"dispatch togglespecialworkspace {sw}",
                ]
            )
