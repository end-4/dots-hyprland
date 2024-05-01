#!/usr/bin/env bash
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/functions
source ./scriptdata/installers
source ./scriptdata/options

#####################################################################################
if ! command -v pacman >/dev/null 2>&1;then printf "\e[31m[$0]: pacman not found, it seems that the system is not ArchLinux or Arch-based distros. Aborting...\e[0m\n";exit 1;fi
prevent_sudo_or_root
startask (){
printf "\e[34m[$0]: Hi there! Before we start:\n"
printf 'This script 1. only works for ArchLinux and Arch-based distros.\n'
printf '            2. does not handle system-level/hardware stuff like Nvidia drivers\n'
printf "\e[31m"
printf "Please CONFIRM that you HAVE ALREADY BACKED UP \"$HOME/.config/\" and \"$HOME/.local/\" folders!\n"
printf "\e[0m"
printf "Enter capital \"YES\" (without quotes) to continue:"
read -p " " p
case $p in "YES")sleep 0;; *)echo "Received \"$p\", aborting...";exit 1;;esac
printf '\n'
printf 'Do you want to confirm every time before a command executes?\n'
printf '  y = Yes, ask me before executing each of them. (DEFAULT)\n'
printf '  n = No, just execute them automatically.\n'
printf '  a = Abort.\n'
read -p "====> " p
case $p in
  n)ask=false;;
  a)exit 1;;
  *)ask=true;;
esac
}

case $ask in
  false)sleep 0;;
  *)startask ;;
esac

set -e
#####################################################################################
printf "\e[36m[$0]: 1. Get packages and setup user groups/services\n\e[0m"

# Issue #363
case $SKIP_SYSUPDATE in
  true) sleep 0;;
  *) v sudo pacman -Syu;;
esac

remove_bashcomments_emptylines ${DEPLISTFILE} ./cache/dependencies_stripped.conf
readarray -t pkglist < ./cache/dependencies_stripped.conf

if ! command -v yay >/dev/null 2>&1;then
  if ! command -v paru >/dev/null 2>&1;then
    echo -e "\e[33m[$0]: \"yay\" not found.\e[0m"
    showfun install-yay
    v install-yay
    AUR_HELPER=yay
  else
    echo -e "\e[33m[$0]: \"yay\" not found, but \"paru\" found.\e[0m"
    echo -e "\e[33mIt is not recommended to use \"paru\" as warned in Hyprland Wiki:\e[0m"
    echo -e "\e[33m    \"If you are using the AUR (hyprland-git) package, you will need to cleanbuild to update the package. Paru has been problematic with updating before, use Yay.\"\e[0m"
    echo -e "\e[33mReference: https://wiki.hyprland.org/FAQ/#how-do-i-update\e[0m"
    if $ask;then
      printf "Install \"yay\"?\n"
      printf "  y = Yes, install \"yay\" for me first. (DEFAULT)\n"
      printf "  n = No, use \"paru\" at my own risk.\n"
      printf "  a = Abort.\n"
      sleep 2
      read -p "====> " p
      case $p in
        [Nn]) AUR_HELPER=paru;;
        [Aa]) echo -e "\e[34mAlright, aborting...\e[0m";exit 1;;
        *) v paru -S --needed --noconfirm yay-bin;
           AUR_HELPER=yay;;
      esac
    else
      AUR_HELPER=paru
    fi
  fi
else AUR_HELPER=yay
fi

if $ask;then
  # execute per element of the array $pkglist
  for i in "${pkglist[@]}";do v $AUR_HELPER -S --needed $i;done
else
  # execute for all elements of the array $pkglist in one line
  v $AUR_HELPER -S --needed --noconfirm ${pkglist[*]}
fi


# https://github.com/end-4/dots-hyprland/issues/389#issuecomment-2040671585
case $SKIP_HYPR_AUR in
  true) sleep 0;;
  *)
    if $ask;then
      v $AUR_HELPER -S --answerclean=a hyprland-git
    else
      v $AUR_HELPER -S --answerclean=a --noconfirm hyprland-git
    fi
    ;;
esac

# https://github.com/end-4/dots-hyprland/issues/428#issuecomment-2081690658
# https://github.com/end-4/dots-hyprland/issues/428#issuecomment-2081701482
# https://github.com/end-4/dots-hyprland/issues/428#issuecomment-2081707099
pymyc=(python-materialyoucolor-git gradience-git python-libsass python-material-color-utilities)
case $SKIP_PYMYC_AUR in
  true) sleep 0;;
  *)
    if $ask;then
      v $AUR_HELPER -S --answerclean=a ${pymyc[@]}
    else
      v $AUR_HELPER -S --answerclean=a --noconfirm ${pymyc[@]}
    fi
    ;;
esac

## Optional dependencies
if pacman -Qs ^plasma-browser-integration$ ;then SKIP_PLASMAINTG=true;fi
case $SKIP_PLASMAINTG in
  true) sleep 0;;
  *)
    if $ask;then
      echo -e "\e[33m[$0]: NOTE: The size of \"plasma-browser-integration\" is about 250 MiB.\e[0m"
      echo -e "\e[33mIt is needed if you want playtime of media in Firefox to be shown on the music controls widget.\e[0m"
      echo -e "\e[33mInstall it? [y/N]\e[0m"
      read -p "====> " p
    else
      p=y
    fi
    case $p in
      y) x sudo pacman -S --needed --noconfirm plasma-browser-integration ;;
      *) echo "Ok, won't install"
    esac
    ;;
esac

v sudo usermod -aG video,i2c,input "$(whoami)"
v bash -c "echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf"
v systemctl --user enable ydotool --now

#####################################################################################
printf "\e[36m[$0]: 2. Installing parts from source repo\e[0m\n"
sleep 1

case $SKIP_AGS in
  true) sleep 0;;
  *)
    if command -v ags >/dev/null 2>&1;then
      echo -e "\e[33m[$0]: Command \"ags\" already exists, no need to install.\e[0m"
      echo -e "\e[34mYou can reinstall it in order to update to the latest version anyway.\e[0m"
      ask_ags=$ask
    else ask_ags=true
    fi
    if $ask_ags;then showfun install-ags;v install-ags;fi
    ;;
esac

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

if $(test -d /usr/local/share/icons/Bibata-Modern-Classic); then
  echo -e "\e[33m[$0]: Cursor theme \"Bibata-Modern-Classic\" already exists, no need to install.\e[0m"
  echo -e "\e[34mYou can reinstall it in order to update to the latest version anyway.\e[0m"
  ask_bibata=$ask
else ask_bibata=true
fi
if $ask_bibata;then showfun install-bibata;v install-bibata;fi

if command -v LaTeX >/dev/null 2>&1;then
  echo -e "\e[33m[$0]: Program \"MicroTeX\" already exists, no need to install.\e[0m"
  echo -e "\e[34mYou can reinstall it in order to update to the latest version anyway.\e[0m"
  ask_MicroTeX=$ask
else ask_MicroTeX=true
fi
if $ask_MicroTeX;then showfun install-MicroTeX;v install-MicroTeX;fi

#####################################################################################
printf "\e[36m[$0]: 3. Copying + Configuring\e[0m\n"

# In case some folders does not exists
v mkdir -p "$HOME"/.{config,cache,local/{bin,share}}

# `--delete' for rsync to make sure that
# original dotfiles and new ones in the SAME DIRECTORY
# (eg. in ~/.config/hypr) won't be mixed together

# MISC (For .config/* but not AGS, not Fish, not Hyprland)
case $SKIP_MISCCONF in
  true) sleep 0;;
  *)
    for i in $(find .config/ -mindepth 1 -maxdepth 1 ! -name 'ags' ! -name 'fish' ! -name 'hypr' -exec basename {} \;); do
      i=".config/$i"
      echo "[$0]: Found target: $i"
      if [ -d "$i" ];then v rsync -av --delete "$i/" "$HOME/$i/"
      elif [ -f "$i" ];then v rsync -av "$i" "$HOME/$i"
      fi
    done
    ;;
esac

case $SKIP_FISH in
  true) sleep 0;;
  *)
    v rsync -av --delete .config/fish/ "$HOME"/.config/fish/
    ;;
esac

# For AGS
case $SKIP_AGS in
  true) sleep 0;;
  *)
    v rsync -av --delete --exclude '/user_options.js' .config/ags/ "$HOME"/.config/ags/
    t="$HOME/.config/ags/user_options.js"
    if [ -f $t ];then
      echo -e "\e[34m[$0]: \"$t\" already exists.\e[0m"
      # v cp -f .config/ags/user_options.js $t.new
      existed_ags_opt=y
    else
      echo -e "\e[33m[$0]: \"$t\" does not exist yet.\e[0m"
      v cp .config/ags/user_options.js $t
      existed_ags_opt=n
    fi
    ;;
esac

# For Hyprland
case $SKIP_HYPRLAND in
  true) sleep 0;;
  *)
    v rsync -av --delete --exclude '/custom' --exclude '/hyprland.conf' .config/hypr/ "$HOME"/.config/hypr/
    t="$HOME/.config/hypr/hyprland.conf"
    if [ -f $t ];then
      echo -e "\e[34m[$0]: \"$t\" already exists.\e[0m"
      v cp -f .config/hypr/hyprland.conf $t.new
      existed_hypr_conf=y
    else
      echo -e "\e[33m[$0]: \"$t\" does not exist yet.\e[0m"
      v cp .config/hypr/hyprland.conf $t
      existed_hypr_conf=n
    fi
    t="$HOME/.config/hypr/custom"
    if [ -d $t ];then
      echo -e "\e[34m[$0]: \"$t\" already exists, will not do anything.\e[0m"
    else
      echo -e "\e[33m[$0]: \"$t\" does not exist yet.\e[0m"
      v rsync -av --delete .config/hypr/custom/ $t/
    fi
    ;;
esac


# some foldes (eg. .local/bin) should be processed separately to avoid `--delete' for rsync,
# since the files here come from different places, not only about one program.
v rsync -av ".local/bin/" "$HOME/.local/bin/"

# Dark mode by default
v gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Prevent hyprland from not fully loaded
sleep 1
try hyprctl reload

existed_zsh_conf=n
grep -q 'source ~/.config/zshrc.d/dots-hyprland.zsh' ~/.zshrc && existed_zsh_conf=y

#####################################################################################
printf "\e[36m[$0]: Finished. See the \"Import Manually\" folder and grab anything you need.\e[0m\n"
printf "\n"
printf "\e[36mIf you are new to Hyprland, please read\n"
printf "https://end-4.github.io/dots-hyprland-wiki/en/i-i/01setup/#post-installation\n"
printf "for hints on launching Hyprland.\e[0m\n"
printf "\n"
printf "\e[36mIf you are already running Hyprland,\e[0m\n"
printf "\e[36mPress \e[30m\e[46m Ctrl+Super+T \e[0m\e[36m to select a wallpaper\e[0m\n"
printf "\e[36mPress \e[30m\e[46m Super+/ \e[0m\e[36m for a list of keybinds\e[0m\n"
printf "\n"

case $existed_ags_opt in
  y) printf "\n\e[33m[$0]: Warning: \"~/.config/ags/user_options.js\" already existed before and we didn't overwrite it. \e[0m\n"
#    printf "\e[33mPlease use \"~/.config/ags/user_options.js.new\" as a reference for a proper format.\e[0m\n"
;;esac
case $existed_hypr_conf in
  y) printf "\n\e[33m[$0]: Warning: \"~/.config/hypr/hyprland.conf\" already existed before and we didn't overwrite it. \e[0m\n"
     printf "\e[33mPlease use \"~/.config/hypr/hyprland.conf.new\" as a reference for a proper format.\e[0m\n"
     printf "\e[33mIf this is your first time installation, you must overwrite \"~/.config/hypr/hyprland.conf\" with \"~/.config/hypr/hyprland.conf.new\".\e[0m\n"
;;esac
