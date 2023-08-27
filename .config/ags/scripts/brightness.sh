#!/usr/bin/env bash

light
udevadm monitor | rg --line-buffered "backlight" | while read -r _; do
  light
done