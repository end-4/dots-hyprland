#!/usr/bin/env bash
cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/environment-variables
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
printf "Please CONFIRM that you HAVE ALREADY BACKED UP \"$XDG_CONFIG_HOME\" and \"$HOME/.local/\" folders!\n"
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

# Use yay. Because paru do not support cleanbuild.
# Also see https://wiki.hyprland.org/FAQ/#how-do-i-update
if ! command -v yay >/dev/null 2>&1;then
  echo -e "\e[33m[$0]: \"yay\" not found.\e[0m"
  showfun install-yay
  v install-yay
fi

# Install extra packages from dependencies.conf as declared by the user
if (( ${#pkglist[@]} != 0 )); then
	if $ask; then
		# execute per element of the array $pkglist
		for i in "${pkglist[@]}";do v yay -S --needed $i;done
	else
		# execute for all elements of the array $pkglist in one line
		v yay -S --needed --noconfirm ${pkglist[*]}
	fi
fi

# Convert old dependencies to non explicit dependencies so that they can be orphaned if not in meta packages
set-explicit-to-implicit() {
	remove_bashcomments_emptylines ./scriptdata/previous_dependencies.conf ./cache/old_deps_stripped.conf
	readarray -t old_deps_list < ./cache/old_deps_stripped.conf
	pacman -Qeq > ./cache/pacman_explicit_packages
	readarray -t explicitly_installed < ./cache/pacman_explicit_packages

	echo "Attempting to set previously explicitly installed deps as implicit..."
	for i in "${explicitly_installed[@]}"; do for j in "${old_deps_list[@]}"; do
		[ "$i" = "$j" ] && yay -D --asdeps "$i"
	done; done

	return 0
}

$ask && echo "Attempt to set previously explicitly installed deps as implicit? "
$ask && showfun set-explicit-to-implicit
v set-explicit-to-implicit

# https://github.com/end-4/dots-hyprland/issues/581
# yay -Bi is kinda hit or miss, instead cd into the relevant directory and manually source and install deps
install-local-pkgbuild() {
	local location=$1
	local installflags=$2

	x pushd $location

	source ./PKGBUILD
	x yay -S $installflags --asdeps "${depends[@]}"
	x makepkg -si --noconfirm

	x popd
}

# Install core dependencies from the meta-packages
metapkgs=(./arch-packages/illogical-impulse-{audio,backlight,basic,fonts-themes,gnome,gtk,portal,python,screencapture,widgets})
metapkgs+=(./arch-packages/illogical-impulse-ags)
metapkgs+=(./arch-packages/illogical-impulse-microtex-git)
metapkgs+=(./arch-packages/illogical-impulse-oneui4-icons-git)
[[ -f /usr/share/icons/Bibata-Modern-Classic/index.theme ]] || \
  metapkgs+=(./arch-packages/illogical-impulse-bibata-modern-classic-bin)
try sudo pacman -R illogical-impulse-microtex

for i in "${metapkgs[@]}"; do
	metainstallflags="--needed"
	$ask && showfun install-local-pkgbuild || metainstallflags="$metainstallflags --noconfirm"
	v install-local-pkgbuild "$i" "$metainstallflags"
done

# https://github.com/end-4/dots-hyprland/issues/428#issuecomment-2081690658
# https://github.com/end-4/dots-hyprland/issues/428#issuecomment-2081701482
# https://github.com/end-4/dots-hyprland/issues/428#issuecomment-2081707099
case $SKIP_PYMYC_AUR in
  true) sleep 0;;
  *)
	  pymycinstallflags=""
	  $ask && showfun install-local-pkgbuild || pymycinstallflags="$pymycinstallflags --noconfirm"
	  v install-local-pkgbuild "./arch-packages/illogical-impulse-pymyc-aur" "$pymycinstallflags"
    ;;
esac


# Why need cleanbuild? see https://github.com/end-4/dots-hyprland/issues/389#issuecomment-2040671585
# Why install deps by running a seperate command? see pinned comment of https://aur.archlinux.org/packages/hyprland-git
case $SKIP_HYPR_AUR in
  true) sleep 0;;
  *)
	  hyprland_installflags="-S"
	  $ask || hyprland_installflags="$hyprland_installflags --noconfirm"
    v yay $hyprland_installflags --asdeps hyprutils-git hyprlang-git hyprcursor-git hyprwayland-scanner-git
    v yay $hyprland_installflags --answerclean=a hyprland-git
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
v gsettings set org.gnome.desktop.interface font-name 'Rubik 11'

#####################################################################################
printf "\e[36m[$0]: 2. Installing parts from source repo\e[0m\n"
sleep 1

#####################################################################################
printf "\e[36m[$0]: 3. Copying + Configuring\e[0m\n"

# In case some folders does not exists
v mkdir -p $XDG_BIN_HOME $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME

# `--delete' for rsync to make sure that
# original dotfiles and new ones in the SAME DIRECTORY
# (eg. in ~/.config/hypr) won't be mixed together

# MISC (For .config/* but not AGS, not Fish, not Hyprland)
case $SKIP_MISCCONF in
  true) sleep 0;;
  *)
    for i in $(find .config/ -mindepth 1 -maxdepth 1 ! -name 'ags' ! -name 'fish' ! -name 'hypr' -exec basename {} \;); do
#      i=".config/$i"
      echo "[$0]: Found target: .config/$i"
      if [ -d ".config/$i" ];then v rsync -av --delete ".config/$i/" "$XDG_CONFIG_HOME/$i/"
      elif [ -f ".config/$i" ];then v rsync -av ".config/$i" "$XDG_CONFIG_HOME/$i"
      fi
    done
    ;;
esac

case $SKIP_FISH in
  true) sleep 0;;
  *)
    v rsync -av --delete .config/fish/ "$XDG_CONFIG_HOME"/fish/
    ;;
esac

# For AGS
case $SKIP_AGS in
  true) sleep 0;;
  *)
    v rsync -av --delete --exclude '/user_options.js' .config/ags/ "$XDG_CONFIG_HOME"/ags/
    t="$XDG_CONFIG_HOME/ags/user_options.js"
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
    v rsync -av --delete --exclude '/custom' --exclude '/hyprland.conf' .config/hypr/ "$XDG_CONFIG_HOME"/hypr/
    t="$XDG_CONFIG_HOME/hypr/hyprland.conf"
    if [ -f $t ];then
      echo -e "\e[34m[$0]: \"$t\" already exists.\e[0m"
      v cp -f .config/hypr/hyprland.conf $t.new
      existed_hypr_conf=y
    else
      echo -e "\e[33m[$0]: \"$t\" does not exist yet.\e[0m"
      v cp .config/hypr/hyprland.conf $t
      existed_hypr_conf=n
    fi
    t="$XDG_CONFIG_HOME/hypr/custom"
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
v rsync -av ".local/bin/" "$XDG_BIN_HOME"

# Dark mode by default
v gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Prevent hyprland from not fully loaded
sleep 1
try hyprctl reload

existed_zsh_conf=n
grep -q 'source ${XDG_CONFIG_HOME:-~/.config}/zshrc.d/dots-hyprland.zsh' ~/.zshrc && existed_zsh_conf=y

warn_files=()
warn_files_tests=()
warn_files_tests+=(/usr/local/bin/ags)
warn_files_tests+=(/usr/local/etc/pam.d/ags)
warn_files_tests+=(/usr/local/lib/{GUtils-1.0.typelib,Gvc-1.0.typelib,libgutils.so,libgvc.so})
warn_files_tests+=(/usr/local/share/com.github.Aylur.ags)
warn_files_tests+=(/usr/local/share/fonts/TTF/Rubik{,-Italic}'[wght]'.ttf)
warn_files_tests+=(/usr/local/share/licenses/ttf-rubik)
warn_files_tests+=(/usr/local/share/fonts/TTF/Gabarito-{Black,Bold,ExtraBold,Medium,Regular,SemiBold}.ttf)
warn_files_tests+=(/usr/local/share/licenses/ttf-gabarito)
warn_files_tests+=(/usr/local/share/icons/OneUI{,-dark,-light})
warn_files_tests+=(/usr/local/share/icons/Bibata-Modern-Classic)
warn_files_tests+=(/usr/local/bin/{LaTeX,res})
for i in ${warn_files_tests[@]}; do
  echo $i
  test -f $i && warn_files+=($i)
  test -d $i && warn_files+=($i)
done

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
  y) printf "\n\e[33m[$0]: Warning: \"$XDG_CONFIG_HOME/ags/user_options.js\" already existed before and we didn't overwrite it. \e[0m\n"
#    printf "\e[33mPlease use \"$XDG_CONFIG_HOME/ags/user_options.js.new\" as a reference for a proper format.\e[0m\n"
;;esac
case $existed_hypr_conf in
  y) printf "\n\e[33m[$0]: Warning: \"$XDG_CONFIG_HOME/hypr/hyprland.conf\" already existed before and we didn't overwrite it. \e[0m\n"
     printf "\e[33mPlease use \"$XDG_CONFIG_HOME/hypr/hyprland.conf.new\" as a reference for a proper format.\e[0m\n"
     printf "\e[33mIf this is your first time installation, you must overwrite \"$XDG_CONFIG_HOME/hypr/hyprland.conf\" with \"$XDG_CONFIG_HOME/hypr/hyprland.conf.new\".\e[0m\n"
;;esac

if [[ ! -z "${warn_files[@]}" ]]; then
  printf "\n\e[31m[$0]: \!! Important \!! : Please delete \e[0m ${warn_files[*]} \e[31m manually as soon as possible, since we\'re now using AUR package or local PKGBUILD to install them for Arch(based) Linux distros, and they'll take precedence over our installation, or at least take up more space.\e[0m\n"
fi
