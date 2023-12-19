#!/usr/bin/env bash

# Undo Step 3: Removing copied config and local folders
echo 'Removing copied config and local folders...'
rm -rf "$HOME/.config/ags fish frontconfig foot fuzzel gtklock hypr mpv swaylock wlogout starship.toml"
rm -rf "$HOME/.local/bin"

# Undo Step 2: Uninstall AGS
echo 'Uninstalling AGS...'
sudo meson uninstall -C ~/ags/build
rm -rf ~/ags

# Undo Step 1: Remove added user from video and input groups and remove yay packages
echo 'Removing user from video and input groups and removing packages...'
user=$(whoami)
sudo deluser "$user" video
sudo deluser "$user" input
echo 'User removed from video and input groups.'

# Removing installed yay packages and dependencies

yay -Rns adw-gtk3-git brightnessctl cava foot fuzzel gjs gojq gradience-git grim gtk-layer-shell gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git libdbusmenu-gtk3 plasma-browser-integration playerctl python-build python-material-color-utilities python-poetry python-pywal ripgrep sassc slurp starship swayidle swaylock swww tesseract ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-space-mono-nerd typescript webp-pixbuf-loader wl-clipboard wlogout yad ydotool


echo 'Uninstall Complete.'
