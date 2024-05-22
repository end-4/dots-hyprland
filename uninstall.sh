#!/usr/bin/env bash
cd "$(dirname "$0")"

function v() {
  echo -e "[$0]: \e[32mNow executing:\e[0m"
  echo -e "\e[32m$@\e[0m"
  "$@"
}

printf 'Hi there!\n'
printf 'This script 1. will uninstall [end-4/dots-hyprland > illogical-impulse] dotfiles\n'
printf '            2. will try to revert *mostly everything* installed using install.sh, so it'\''s pretty destructive\n'
printf '            3. has not been tested, use at your own risk.\n'
printf '            4. assumes you have default xdg dirs (for example config folder in ~/.config).\n'
printf '            5. will show all commands that it runs.\n'
printf 'Ctrl+C to exit. Enter to continue.\n'
read -r
set -e
##############################################################################################################################

# Undo Step 3: Removing copied config and local folders
printf '\e[36mRemoving copied config and local folders...\n\e[97m'

for i in ags fish fontconfig foot fuzzel hypr mpv wlogout "starship.toml" rubyshot
  do v rm -rf "$HOME/.config/$i"
done

v rm -rf "$HOME/.local/bin/fuzzel-emoji"
v rm -rf "$HOME/.cache/ags"
v sudo rm -rf "$HOME/.local/state/ags"

##############################################################################################################################

# Undo Step 2: Uninstall AGS - Disabled for now, check issues
# echo 'Uninstalling AGS...'
# sudo meson uninstall -C ~/ags/build
# rm -rf ~/ags

##############################################################################################################################

# Undo Step 1: Remove added user from video, i2c, and input groups and remove yay packages
printf '\e[36mRemoving user from video, i2c, and input groups and removing packages...\n\e[97m'
user=$(whoami)
v sudo deluser "$user" video
v sudo deluser "$user" i2c
v sudo deluser "$user" input
v sudo rm /etc/modules-load.d/i2c-dev.conf

##############################################################################################################################
read -p "Do you want to uninstall packages used by the dotfiles?\nCtrl+C to exit, or press Enter to proceed"

# Removing installed yay packages and dependencies
v yay -Rns adw-gtk3-git brightnessctl cava ddcutil foot fuzzel gjs gojq gradience-git grim gtk-layer-shell hyprland-git lexend-fonts-git libdbusmenu-gtk3 plasma-browser-integration playerctl python-build python-material-color-utilities python-poetry python-pywal ripgrep sassc swww slurp starship swayidle hyprlock-git tesseract ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-space-mono-nerd typescript webp-pixbuf-loader wl-clipboard wlogout yad ydotool

printf '\e[36mUninstall Complete.\n\e[97m'
