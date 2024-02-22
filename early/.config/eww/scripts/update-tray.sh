#!/usr/bin/bash

if [[ "$(pidof waybar)" == "" ]]; then
  eww update tray_is_open=false
else
  eww update tray_is_open=true
fi
