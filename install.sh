#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

printf 'Hi there!\n'
printf 'This script 1. only works for ArchLinux and Arch-based distros.\n'
printf '            2. has not been tested, use at your own risk.\n'
printf '            3. will show all commands that it runs.\n'
printf "\e[36m== BACKUP YOUR CONFIG FOLDER IF NEEDED! ==\n"
printf 'Ctrl+C to exit. Enter to continue.\n'
read -r
#####################################################################################
printf '\e[36m1. Get packages and add user to video/input groups\n\e[97m'

set -v
yay -S --needed --noconfirm blueberry brightnessctl coreutils curl fish foot fuzzel gjs gnome-bluetooth-3.0 gnome-control-center gnome-keyring gobject-introspection grim gtk3 gtk-layer-shell libdbusmenu-gtk3 meson networkmanager npm plasma-browser-integration playerctl polkit-gnome python-pywal ripgrep sassc slurp starship swayidle swaylock typescript upower xorg-xrandr webp-pixbuf-loader wget wireplumber wl-clipboard tesseract yad ydotool adw-gtk3-git cava gojq gradience-git gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git python-material-color-utilities python-pywal python-poetry python-build python-pillow swaylock-effects-git swww ttf-material-symbols-variable-git ttf-space-mono-nerd ttf-jetbrains-mono-nerd wayland-idle-inhibitor-git wlogout wlsunset-git

user=$(whoami)
sudo usermod -aG video "$user"
sudo usermod -aG input "$user"

#####################################################################################
set +v
printf '\e[36m2. Installing AGS manually\e[97m\n'
sleep 1
set -v
git clone --recursive https://github.com/Aylur/ags.git
set +v
sleep 1
set -v
npm install && meson setup build
meson install -C build
#####################################################################################
set +v
printf '\e[36m3. Copying\e[97m\n'

set -v
cp -r "./.config" "$HOME"
cp -r "./.local" "$HOME"
#####################################################################################
set +v
printf 'Finished. See the "Import manually" folder and grab anything you need.\e[97m\n'
printf 'Press Ctrl+Super+T to select a wallpaper\e[97m\n'
printf 'Press Super+/ for a list of keybinds\e[97m\n'



