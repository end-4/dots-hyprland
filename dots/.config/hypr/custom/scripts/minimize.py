#!/usr/bin/python3

import os
import subprocess
import json
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("window", type=str)
parser.add_argument("exec", type=str)
args = parser.parse_args()

clients_json = subprocess.run(
    ["hyprctl", "-j", "clients"], capture_output=True, text=True
).stdout
clients = json.loads(clients_json)

win_attr, win_data = args.window.split(":")

exists = False
window = None

for i in clients:
    if i[win_attr] == win_data:
        window = i
        exists = True
        break

if not exists:
    os.system(f"hyprctl dispatch exec [float] '{args.exec}'")
    os.system(f"hyprctl dispatch focuswindow {args.window}")
    print("started")
    exit()

current_window_json = subprocess.run(
    ["hyprctl", "-j", "activewindow"], capture_output=True, text=True
).stdout
current_window = json.loads(current_window_json)

if current_window != {}:
    current_workspace = current_window["workspace"]["id"]
    ws = current_window["workspace"]["name"]
else:
    current_wokrspace_json = subprocess.run(
        ["hyprctl", "-j", "activeworkspace"], capture_output=True, text=True
    ).stdout
    current_workspace = json.loads(current_wokrspace_json)["id"]
    ws = current_workspace


if window["workspace"]["id"] != current_workspace:
    os.system(f"hyprctl dispatch movetoworkspacesilent {ws},{args.window}")
    os.system(f"hyprctl dispatch focuswindow {args.window}")

else:
    if window["focusHistoryID"] == 0:
        os.system(f"hyprctl dispatch movetoworkspacesilent 99,{args.window}")
    else:
        os.system(f"hyprctl dispatch focuswindow {args.window}")
