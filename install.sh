#!/usr/bin/env bash

echo 'Hi there!'
echo 'This script 1. only works for ArchLinux and Arch-based distros.'
echo '            2. is not tested, use at your own risk.'
echo '            3. will show all commands that it runs.'
echo '            4. should be run from its folder.'
echo '== BACKUP YOUR CONFIG FOLDER IF NEEDED! =='
echo 'Ctrl+C to exit. Enter to continue.'
read
#####################################################################################
echo '1. Get packages and add user to video/input groups'

echo 'yay -S brightnessctl coreutils curl fish foot fuzzel gjs gnome-bluetooth-3.0 gnome-control-center gnome-keyring gobject-introspection grim gtk3 gtk-layer-shell libdbusmenu-gtk3 meson networkmanager nlohmann-json npm plasma-browser-integration playerctl polkit-gnome python-pywal ripgrep sassc slurp starship swayidle swaylock typescript upower xorg-xrandr webp-pixbuf-loader wget wireplumber wl-clipboard tesseract yad ydotool adw-gtk3-git cava gojq gradience-git gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git python-material-color-utilities python-pywal python-poetry python-build python-pillow swww ttf-material-symbols-variable-git ttf-space-mono-nerd ttf-jetbrains-mono-nerd wlogout'
yay -S brightnessctl coreutils curl fish foot fuzzel gjs gnome-bluetooth-3.0 gnome-control-center gnome-keyring gobject-introspection grim gtk3 gtk-layer-shell libdbusmenu-gtk3 meson networkmanager nlohmann-json npm plasma-browser-integration playerctl polkit-gnome python-pywal ripgrep sassc slurp starship swayidle swaylock typescript upower xorg-xrandr webp-pixbuf-loader wget wireplumber wl-clipboard tesseract yad ydotool adw-gtk3-git cava gojq gradience-git gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git python-material-color-utilities python-pywal python-poetry python-build python-pillow swww ttf-material-symbols-variable-git ttf-space-mono-nerd ttf-jetbrains-mono-nerd wlogout

user=$(whoami)
echo "sudo usermod -aG video $user"
sudo usermod -aG video "$user" || echo "failed to add user to video group"
echo "sudo usermod -aG input $user"
sudo usermod -aG input "$user" || echo "failed to add user to input group"
echo "Step 1 Complete."
#####################################################################################
echo '2. Installing AGS manually'
sleep 1
echo 'git clone --recursive https://github.com/Aylur/ags.git && cd ags'
git clone --recursive https://github.com/Aylur/ags.git && cd ags || echo "failed to clone into ags. Aborting..." && exit
echo "Done Cloning! Setting up npm and meson..."
sleep 1
echo 'npm install && meson setup build'
npm install && meson setup build
echo 'meson install -C build'
echo '(Make sure you say yes when asked to use sudo here)'
meson install -C build
#####################################################################################
echo '3. Copying'

echo 'cp -r "./.config" "$HOME"'
cp -r "./.config" "$HOME" || echo "cp threw error. You could cp this yourself."
echo 'cp -r "./.local" "$HOME"'
cp -r "./.local" "$HOME" || echo "cp threw error. You could cp this yourself."
#####################################################################################
echo 'Finished. See the "Import manually" folder and grab anything you need.'



