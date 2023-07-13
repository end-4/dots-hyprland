#!/usr/bin/bash

eww update dynamicright_module_page=2
eww update flash_notif=true
sleep 4
eww update dynamicright_module_page=1
eww update flash_notif=false