#!/bin/python3

import os
import subprocess

result = subprocess.run(
    "ps a | grep youtube-music | grep electron",
    shell=True,
    capture_output=True,
    text=True,
)
music_is_open = len(result.stdout.strip().split("\n")) > 1

if not music_is_open:
    os.system('hyprctl dispatch exec "[workspace special:music silent]" youtube-music')

os.system("playerctl play-pause")
