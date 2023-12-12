#!/usr/bin/env bash

echo 'Greetings! This script will help you install this hyprland config.'
echo 'BACKUP YOUR CONFIG FOLDER IF NEEDED.'
echo 'All commands will be shown.'
echo 'Ctrl+C to exit. Enter to continue.'
read
#####################################################################################
echo '1. Get packages and add user to video/input groups'

echo 'yay -S brightnessctl coreutils curl fish foot fuzzel gjs gnome-bluetooth-3.0 gnome-control-center gnome-keyring gobject-introspection grim gtk3 gtk-layer-shell libdbusmenu-gtk3 meson networkmanager nlohmann-json npm plasma-browser-integration playerctl polkit-gnome python-pywal ripgrep sassc slurp starship swayidle typescript upower xorg-xrandr webp-pixbuf-loader wget wireplumber tesseract yad ydotool adw-gtk3-git cava gojq gradience-git gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git python-material-color-utilities python-pywal python-poetry python-build python-pillow swww ttf-material-symbols-variable-git ttf-space-mono-nerd ttf-jetbrains-mono-nerd wlogout wl-copy'
yay -S brightnessctl coreutils curl fish foot fuzzel gjs gnome-bluetooth-3.0 gnome-control-center gnome-keyring gobject-introspection grim gtk3 gtk-layer-shell libdbusmenu-gtk3 meson networkmanager nlohmann-json npm plasma-browser-integration playerctl polkit-gnome python-pywal ripgrep sassc slurp starship swayidle typescript upower xorg-xrandr webp-pixbuf-loader wget wireplumber tesseract yad ydotool adw-gtk3-git cava gojq gradience-git gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git python-material-color-utilities python-pywal python-poetry python-build python-pillow swww ttf-material-symbols-variable-git ttf-space-mono-nerd ttf-jetbrains-mono-nerd wlogout wl-copy

user=$(whoami)
echo "sudo usermod -aG video $user"
sudo usermod -aG video "$user"
echo "sudo usermod -aG input $user"
sudo usermod -aG input "$user"
#####################################################################################
echo '2. Install AGS manually'

echo 'git clone --recursive https://github.com/Aylur/ags.git && cd ags'
git clone --recursive https://github.com/Aylur/ags.git && cd ags
echo 'npm install && meson setup build'
npm install && meson setup build 
echo 'meson install -C build'
echo '(Make sure you say yes when asked to use sudo here)'
meson install -C build
#####################################################################################
echo '3. Copying'

echo 'cp -r "./.config" "$HOME"'
cp -r "./.config" "$HOME"
echo 'cp -r "./.local" "$HOME"'
cp -r "./.local" "$HOME"
#####################################################################################
echo 'Finished'


