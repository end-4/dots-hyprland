#!/usr/bin/env bash
cd "$(dirname "$0")"
export base="$(pwd)"

function try { "$@" || sleep 0; }
function v() {
  echo -e "####################################################"
  echo -e "\e[34m[$0]: Next command:\e[0m"
  echo -e "\e[32m$@\e[0m"
  execute=true
  if $ask;then
    while true;do
      echo -e "\e[34mExecute? \e[0m"
      echo "  y = Yes"
      echo "  e = Exit now"
      echo "  s = Skip this command (NOT recommended - your setup might not work correctly)"
      echo "  yesforall = Yes and don't ask again; NOT recommended unless you really sure"
      read -p "====> " p
      case $p in
        [yY]) echo -e "\e[34mOK, executing...\e[0m" ;break ;;
        [eE]) echo -e "\e[34mExiting...\e[0m" ;exit ;break ;;
        [sS]) echo -e "\e[34mAlright, skipping this one...\e[0m" ;execute=false ;break ;;
        "yesforall") echo -e "\e[34mAlright, won't ask again. Executing...\e[0m"; ask=false ;break ;;
        *) echo -e "\e[31mPlease enter [y/e/s/yesforall].\e[0m";;
      esac
    done
  fi
  if $execute;then x "$@";else
    echo -e "\e[33m[$0]: Skipped \"$@\"\e[0m"
  fi
}
# When use v() for a defined function, use x() INSIDE its definition to catch errors.
function x() {
  if "$@";then cmdstatus=0;else cmdstatus=1;fi # 0=normal; 1=failed; 2=failed but ignored
  while [ $cmdstatus == 1 ] ;do
    echo -e "\e[31m[$0]: Command \"\e[32m$@\e[31m\" has failed."
    echo -e "You may need to resolve the problem manually BEFORE repeating this command.\e[0m"
    echo "  r = Repeat this command (DEFAULT)"
    echo "  e = Exit now"
    echo "  i = Ignore this error and continue (your setup might not work correctly)"
    read -p " [R/e/i]: " p
    case $p in
      [iI]) echo -e "\e[34mAlright, ignore and continue...\e[0m";cmdstatus=2;;
      [eE]) echo -e "\e[34mAlright, will exit.\e[0m";break;;
      *) echo -e "\e[34mOK, repeating...\e[0m"
         if "$@";then cmdstatus=0;else cmdstatus=1;fi
         ;;
    esac
  done
  case $cmdstatus in
    0) echo -e "\e[34m[$0]: Command \"\e[32m$@\e[34m\" finished.\e[0m";;
    1) echo -e "\e[31m[$0]: Command \"\e[32m$@\e[31m\" has failed. Exiting...\e[0m";exit 1;;
    2) echo -e "\e[31m[$0]: Command \"\e[32m$@\e[31m\" has failed but ignored by user.\e[0m";;
  esac
}
function showfun() {
  echo -e "\e[34m[$0]: The definition of function \"$1\" is as follows:\e[0m"
  printf "\e[32m"
  type -a $1
  printf "\e[97m"
}
#####################################################################################
# For debugging
# ask=false
# mkdir -p /tmp/test1
# v mkdir /tmp/test1
# 
# echo "debug part fin";exit
#####################################################################################
if ! command -v pacman >/dev/null 2>&1;then printf "\e[31m[$0]: pacman not found, it seems that the system is not ArchLinux or Arch-based distros. Aborting...\e[0m\n";exit 1;fi
startask (){
printf "\e[34m[$0]: Hi there!\n"
printf 'This script 1. only works for ArchLinux and Arch-based distros.\n'
printf '            2. has not been fully tested, use at your own risk.\n'
printf "\e[31m"
printf "Please CONFIRM that you HAVE ALREADY BACKED UP \"$HOME/.config/\" and \"$HOME/.local/\" folders!\n"
printf "\e[97m"
printf "Enter capital \"YES\" (without quotes) to continue:"
read -p " " p
case $p in "YES")sleep 0;; *)exit;;esac
printf '\n'
printf 'Do you want to confirm every time before a command executes?\n'
printf '  y = Yes, ask me before executing each of them. (RECOMMENDED)\n'
printf '  n = No, just execute them automatically.\n'
printf '  a = Abort. (DEFAULT)\n'
read -p "====> " p
case $p in
  y)ask=true;;
  n)ask=false;;
  *)exit;;
esac
}

case $1 in
  "-f")ask=false;;
  *)startask ;;
esac

set -e
#####################################################################################
printf "\e[36m[$0]: 1. Get packages and add user to video/input groups\n\e[97m"

# Each line as an element of the array $pkglist
readarray -t pkglist < dependencies.txt
# NOTE: wayland-idle-inhibitor-git is for providing `wayland-idle-inhibitor.py' used by the `Keep system awake' button in `.config/ags/widgets/sideright/quicktoggles.js'.

# yay will be installed as AUR package and upgrade there, no need to build here in cache/yay .
install-yay() {
  x sudo pacman -Sy --needed --noconfirm base-devel
  x git clone https://aur.archlinux.org/yay-bin.git /tmp/buildyay
  x cd /tmp/buildyay
  x makepkg -o
  x makepkg -se
  x makepkg -i --noconfirm
  x cd $base
  rm -rf /tmp/buildyay
}

if ! command -v yay >/dev/null 2>&1;then
  echo -e "\e[33m[$0]: \"yay\" not found.\e[0m"
  showfun install-yay
  v install-yay
fi

if $ask;then
  # execute per element of the array $pkglist
  for i in "${pkglist[@]}";do v yay -S --needed $i;done
else
  # execute for all elements of the array $pkglist in one line
  v yay -S --needed --noconfirm "${pkglist[*]}"
fi

v sudo usermod -aG video "$(whoami)"
v sudo usermod -aG input "$(whoami)"

#####################################################################################
printf "\e[36m[$0]: 2. Installing AGS and fonts from git repo\e[97m\n"
sleep 1

install-ags (){
  x mkdir -p $base/cache/ags
  x cd $base/cache/ags
  try git init -b main
  try git remote add origin https://github.com/Aylur/ags.git
  x git pull origin main && git submodule update --init --recursive
  x npm install
  x meson setup build
  x meson install -C build
  x cd $base
}
install-Rubik (){
  x mkdir -p $base/cache/Rubik
  x cd $base/cache/Rubik
  try git init -b main
  try git remote add origin https://github.com/googlefonts/rubik.git
  x git pull origin main && git submodule update --init --recursive
	x sudo mkdir -p /usr/local/share/fonts/TTF/
	x sudo cp fonts/variable/Rubik*.ttf /usr/local/share/fonts/TTF/
	x sudo mkdir -p /usr/local/share/licenses/ttf-rubik/
	x sudo cp OFL.txt /usr/local/share/licenses/ttf-rubik/LICENSE
  x fc-cache -fv
  x cd $base
}
install-Gabarito (){
  x mkdir -p $base/cache/Gabarito
  x cd $base/cache/Gabarito
  try git init -b main
  try git remote add origin https://github.com/naipefoundry/gabarito.git
  x git pull origin main && git submodule update --init --recursive
	x sudo mkdir -p /usr/local/share/fonts/TTF/
	x sudo cp fonts/ttf/Gabarito*.ttf /usr/local/share/fonts/TTF/
	x sudo mkdir -p /usr/local/share/licenses/ttf-gabarito/
	x sudo cp OFL.txt /usr/local/share/licenses/ttf-gabarito/LICENSE
  x fc-cache -fv
  x cd $base
}
install-OneUI4-Icons (){
  x mkdir -p $base/cache/OneUI4-Icons
  x cd $base/cache/OneUI4-Icons
  try git init -b main
  try git remote add origin https://github.com/mjkim0727/OneUI4-Icons.git
  x git pull origin main && git submodule update --init --recursive
  x sudo mkdir -p /usr/local/share/icons
  x sudo cp -r OneUI /usr/local/share/icons
  x sudo cp -r OneUI-dark /usr/local/share/icons
  x sudo cp -r OneUI-light /usr/local/share/icons
  x cd $base
}

if command -v ags >/dev/null 2>&1;then
  echo -e "\e[33m[$0]: Command \"ags\" already exists, no need to install.\e[0m"
  echo -e "\e[34mYou can reinstall it in order to update to the latest version anyway.\e[0m"
  ask_ags=$ask
else ask_ags=true
fi
if $ask_ags;then showfun install-ags;v install-ags;fi

if $(fc-list|grep -q Rubik); then
  echo -e "\e[33m[$0]: Font \"Rubik\" already exists, no need to install.\e[0m"
  echo -e "\e[34mYou can reinstall it in order to update to the latest version anyway.\e[0m"
  ask_Rubik=$ask
else ask_Rubik=true
fi
if $ask_Rubik;then showfun install-Rubik;v install-Rubik;fi

if $(fc-list|grep -q Gabarito); then
  echo -e "\e[33m[$0]: Font \"Gabarito\" already exists, no need to install.\e[0m"
  echo -e "\e[34mYou can reinstall it in order to update to the latest version anyway.\e[0m"
  ask_Gabarito=$ask
else ask_Gabarito=true
fi
if $ask_Gabarito;then showfun install-Gabarito;v install-Gabarito;fi

if $(test -d /usr/local/share/icons/OneUI); then
  echo -e "\e[33m[$0]: Icon pack \"OneUI\" already exists, no need to install.\e[0m"
  echo -e "\e[34mYou can reinstall it in order to update to the latest version anyway.\e[0m"
  ask_OneUI=$ask
else ask_OneUI=true
fi
if $ask_OneUI;then showfun install-OneUI;v install-OneUI;fi
#####################################################################################
printf "\e[36m[$0]: 3. Copying\e[97m\n"

# In case ~/.local/bin does not exists
v mkdir -p "$HOME/.local/bin" "$HOME/.local/share"

# `--delete' for rsync to make sure that
# original dotfiles and new ones in the SAME DIRECTORY
# (eg. in ~/.config/hypr) won't be mixed together

for i in .config/*
do
  echo "[$0]: Found target: $i"
  if [ -d "$i" ];then v rsync -av --delete "$i/" "$HOME/$i/"
  elif [ -f "$i" ];then v rsync -av "$i" "$HOME/$i"
  fi
done

target="$HOME/.config/hypr/colors.conf"
test -f $target || { \
  echo -e "\e[34m[$0]: File \"$target\" not found.\e[0m" && \
  v cp "$HOME/.config/hypr/colors_default.conf" $target ; }

# some foldes (eg. .local/bin) should be processed seperately to avoid `--delete' for rsync,
# since the files here come from different places, not only about one program.
v rsync -av ".local/bin/" "$HOME/.local/bin/"

#####################################################################################
printf "\e[36m[$0]: Finished. See the \"Import Manually\" folder and grab anything you need.\e[97m\n"
printf "\e[36mPress \e[30m\e[46m Ctrl+Super+T \e[0m\e[36m to select a wallpaper\e[97m\n"
printf "\e[36mPress \e[30m\e[46m Super+/ \e[0m\e[36m for a list of keybinds\e[97m\n"
