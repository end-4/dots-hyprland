#!/usr/bin/env bash
cd "$(dirname "$0")"
export base="$(pwd)"

function try { "$@" || sleep 0; }
function v() {
  echo -e "\e[34m[$0]: Next command to be executed:\e[0m"
  echo -e "\e[32m$@\e[0m"
  execute=true
  if $ask;then
    while true;do
      echo -e "\e[34mDo you want to execute the command shown above? \e[0m"
      echo "  y = Yes"
      echo "  e = Exit now"
      echo "  s = Skip this command; NOT recommended (may break functions needed by the dotfiles!)"
      echo "  yesforall = yes and don't ask again; NOT recommended unless you really sure"
      read -p "Enter here [y/e/s/yesforall]:" p
      case $p in
        [yY]) echo -e "\e[34mOK, executing...\e[0m" ;break ;;
        [eE]) echo -e "\e[34mExiting...\e[0m" ;exit ;break ;;
        [sS]) echo -e "\e[34mAlright, skipping this one...\e[0m" ;export execute=false ;break ;;
        "yesforall") echo -e "\e[34mAlright, won't ask again. Executing...\e[0m"; export ask=false ;break ;;
        *) echo -e "\e[31mPlease enter one of [y/e/s/yesforall].\e[0m";;
      esac
    done
  fi
  if $execute;then
  "$@"
  fi
}
#####################################################################################
startask (){
printf "\e[34m[$0]: Hi there!\n"
printf 'This script 1. only works for ArchLinux and Arch-based distros.\n'
printf '            2. has not been fully tested, use at your own risk.\n'
printf "\e[31m"
printf "Please CONFIRM that you HAVE ALREADY BACKED UP \"$HOME/.config/\" and \"$HOME/.local/\" folders!\n"
printf "\e[97m"
printf "Enter the capital \"YES\" (without quotes) to continue: "
read -p " " p
case $p in "YES")sleep 0;; *)exit;;esac
printf '\n'
printf 'Do you want to confirm everytime before a command executes?\n'
printf '      y = Yes, ask me before executing each of them. (RECOMMENDED)\n'
printf '      n = No, just execute them automatically.\n'
printf '      a = Abort. (DEFAULT)\n'
read -p "Enter [y/n/A]: " p
case $p in
  y)export ask=true;;
  n)export ask=false;;
  *)exit;;
esac
}

case $1 in
  "-f")export ask=false;;
  *)startask ;;
esac

set -e
#####################################################################################
printf '\e[36m1. Get packages and add user to video/input groups\n\e[97m'

# Each line as an element of the array $pkglist
readarray -t pkglist < dependencies.txt
# NOTE: wayland-idle-inhibitor-git is for providing `wayland-idle-inhibitor.py' used by the `Keep system awake' button in `.config/ags/widgets/sideright/quicktoggles.js'.

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
printf '\e[36m2. Installing AGS from git repo\e[97m\n'
sleep 1

installags (){
  v git clone --recursive https://github.com/Aylur/ags.git|| \
    if [ -d ags ];then
      printf "\e[36mSeems \"./ags\" already exists.\e[97m\n"
      cd ags
      v git pull
    else exit 1
    fi
  v npm install
  v meson setup build 
  v meson install -C build
  cd $base
}
if command -v ags >/dev/null 2>&1
  then echo -e "\e[34mCommand \"ags\" already exists. Won\'t install ags.\e[0m"
  else installags
fi

#####################################################################################
printf '\e[36m3. Copying\e[97m\n'

# In case ~/.local/bin does not exists
v mkdir -p "$HOME/.local/bin" "$HOME/.local/share"

# `--delete' for rsync to make sure that
# original dotfiles and new ones in the SAME DIRECTORY
# (eg. in ~/.config/hypr) won't be mixed together

for i in .config/*
do
  echo "Found target: $i"
  if [ -d "$i" ];then v rsync -av --delete "$i/" "$HOME/$i/"
  elif [ -f "$i" ];then v rsync -av "$i" "$HOME/$i"
  fi
done

# some foldes (eg. .local/bin) should be processed seperately to avoid `--delete' for rsync,
# since the files here come from different places, not only about one program.
v rsync -av ".local/bin/" "$HOME/.local/bin/"

#####################################################################################
printf "\e[36m[$0]: Finished. See the \"Import Manually\" folder and grab anything you need.\e[97m\n"
printf "\e[36mPress \e[30m\e[46m Ctrl+Super+T \e[0m\e[36m to select a wallpaper\e[97m\n"
printf "\e[36mPress \e[30m\e[46m Super+/ \e[0m\e[36m for a list of keybinds\e[97m\n"
