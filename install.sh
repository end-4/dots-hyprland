#!/usr/bin/env bash
cd "$(dirname "$0")"

function try { "$@" || sleep 0; }
function v() {
  echo -e "[$0]: \e[34mNow executing:\e[0m"
  echo -e "\e[32m$@\e[0m"
  execute=true
  if $ask;then
    while true;do
      echo -e "\e[34mDo you want to execute this command? \e[0m"
      echo "  y = Yes"
      echo "  a = Abort this script"
      echo "  s = Skip this command; NOT recommended unless you really sure"
      echo "  yesforall = yes and don't ask again; NOT recommended unless you really sure"
      read -p "Enter here [y/a/s/yesforall]:" p
      case $p in
        [yY]) echo -e "\e[34mOK, executing...\e[0m" ;break ;;
        [aA]) echo -e "\e[34mAborting...\e[0m" ;exit ;break ;;
        [sS]) echo -e "\e[34mAlright, skipping this one...\e[0m" ;export execute=false ;break ;;
        "yesforall") echo -e "\e[34mAlright, won't ask again. Executing...\e[0m"; export ask=false ;break ;;
        *) echo -e "\e[31mPlease enter one of [y/a/s/yesforall].\e[0m";;
      esac
    done
  fi
  if $execute;then
  "$@"
  fi
}
#####################################################################################
printf "[$0]: Hi there!\n"
printf 'This script 1. only works for ArchLinux and Arch-based distros.\n'
printf '            2. has not been fully tested, use at your own risk.\n'
printf "\e[36m== PLEASE BACKUP \"$HOME/.config\" AND \"$HOME/.local\" BY YOURSELF IF NEEDED! ==\n\e[97m"
printf '\n'
printf 'Do you want to confirm everytime before a command executes?\n'
printf '      y = Yes, ask me before executing each of them. (RECOMMENDED)\n'
printf '      n = No, just execute them automatically.\n'
printf '      E = Exit this script. (DEFAULT)\n'
read -p "Enter y/n/E: " p
case $p in
  y)export ask=true;;
  n)export ask=false; export c=" --noconfirm" ;;
  *)exit;;
esac
set -e
#####################################################################################
printf '\e[36m1. Get packages and add user to video/input groups\n\e[97m'

v yay -S --needed$c blueberry brightnessctl coreutils curl fish foot fuzzel gjs gnome-bluetooth-3.0 gnome-control-center gnome-keyring gobject-introspection grim gtk3 gtk-layer-shell libdbusmenu-gtk3 meson networkmanager npm plasma-browser-integration playerctl polkit-gnome python-pywal ripgrep sassc slurp starship swayidle typescript upower xorg-xrandr webp-pixbuf-loader wget wireplumber wl-clipboard tesseract yad ydotool adw-gtk3-git cava gojq gradience-git gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git python-material-color-utilities python-pywal python-poetry python-build python-pillow swaylock-effects-git swww ttf-material-symbols-variable-git ttf-space-mono-nerd ttf-jetbrains-mono-nerd wayland-idle-inhibitor-git wlogout wlsunset-git hyprpicker-git rsync

v sudo usermod -aG video "$(whoami)"
v sudo usermod -aG input "$(whoami)"

#####################################################################################
printf '\e[36m2. Installing AGS from git repo\e[97m\n'
sleep 1

installags (){
  v git clone --recursive https://github.com/Aylur/ags.git|| \
    if [ -d ags ];then printf "\e[36mSeems \"./ags\" already exists.\e[97m\n";else exit 1;fi
  cd ags 
  v npm install
  v meson setup build 
  v meson install -C build
}
if command -v ags >/dev/null 2>&1
  then echo "Command ags already exists."
  else installags
fi

cd "$(dirname "$0")"
#####################################################################################
printf '\e[36m3. Copying\e[97m\n'

# In case ~/.local/bin does not exists
v mkdir -p "$HOME/.local/bin"

# `--delete' for rsync to make sure that
# original dot files and new ones in the SAME DIRECTORY
# (eg. in ~/.config/hypr) won't be mixed together

for i in .config/*
do
  echo "Found target: $i"
  if [ -d "$i" ];then v rsync -av --delete "$i/" "$HOME/$i/"
  elif [ -f "$i" ];then v rsync -av "$i" "$HOME/$i"
  fi
done

# .local/bin should be processed seperately to avoid `--delete' for rsync,
# since the files here comes from different places, not only one program.
v rsync -av ".local/bin/" "$HOME/.local/bin/"

#####################################################################################
printf "[$0]: \e[36mFinished. See the \"Import Manually\" folder and grab anything you need.\e[97m\n"
printf "\e[36mPress \e[30m\e[46m Ctrl+Super+T \e[0m\e[36m to select a wallpaper\e[97m\n"
printf "\e[36mPress \e[30m\e[46m Super+/ \e[0m\e[36m for a list of keybinds\e[97m\n"
