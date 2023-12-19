#!/usr/bin/env bash

# Undo Step 3: Removing copied config and local folders
echo 'Removing copied config and local folders...'
rm -rf "$HOME/.config"
rm -rf "$HOME/.local"

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

yay -Rns brightnessctl coreutils curl fish foot fuzzel gjs gnome-bluetooth-3.0 gnome-control-center gnome-keyring gobject-introspection grim gtk3 gtk-layer-shell libdbusmenu-gtk3 meson networkmanager nlohmann-json npm plasma-browser-integration playerctl polkit-gnome python-pywal ripgrep sassc slurp starship swayidle swaylock typescript upower xorg-xrandr webp-pixbuf-loader wget wireplumber wl-clipboard tesseract yad ydotool adw-gtk3-git cava gojq gradience-git gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git python-material-color-utilities python-pywal python-poetry python-build python-pillow swww ttf-material-symbols-variable-git ttf-space-mono-nerd ttf-jetbrains-mono-nerd wlogout

echo 'Uninstall Complete.'
