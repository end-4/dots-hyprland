#!/bin/bash
# Online script for install dots-hyprland.

me="-->online-setup<--"
remote_repo=end-4/dots-hyprland
set -e
function try { "$@" || sleep 0; }
function x() {
  if "$@";then cmdstatus=0;else cmdstatus=1;fi # 0=normal; 1=failed; 2=failed but ignored
  while [ $cmdstatus == 1 ] ;do
    echo -e "\e[31m$me: Command \"\e[32m$@\e[31m\" has failed."
    echo -e "You may need to resolve the problem manually BEFORE repeating this command.\e[0m"
    echo "  r = Repeat this command (DEFAULT)"
    echo "  e = Exit now"
    read -p " [R/e]: " p
    case $p in
      [eE]) echo -e "\e[34mAlright, will exit.\e[0m";break;;
      *) echo -e "\e[34mOK, repeating...\e[0m"
         if "$@";then cmdstatus=0;else cmdstatus=1;fi
         ;;
    esac
  done
  case $cmdstatus in
    0) echo -e "\e[34m$me: Command \"\e[32m$@\e[34m\" finished.\e[0m";;
    1) echo -e "\e[31m$me: Command \"\e[32m$@\e[31m\" has failed. Exiting...\e[0m";exit 1;;
  esac
}

command -v pacman || { echo "\"pacman\" not found. This script only work for Arch(-based) Linux distros. Aborting..."; exit 1 ; }

if [ -z "$1" ]; then
  path=~/.cache/dots-hyprland
else
  path="$1"
fi

echo "$me: Downloading repo to $path ..."
x mkdir -p $path
x cd $path
if [ -z "$(ls -A)" ]; then
  x git init -b main
  x git remote add origin https://github.com/$remote_repo
fi
git remote get-url origin|grep -q $remote_repo || { echo "Dir \"$path\" is not empty, nor a git repo of $remote_repo. Aborting..."; exit 1 ; }
x git pull origin main && git submodule update --init --recursive
echo "$me: Downloaded."
echo "$me: Running \"install.sh\"."
x ./install.sh || { echo "$me: Error occured when running \"install.sh\"."; exit 1 ; }
