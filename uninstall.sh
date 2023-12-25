#!/usr/bin/env bash

echo 'Hi there!'
echo 'This script 1. will uninstall [end-4/dots-hyprland > illogical-impulse] dotfiles'
echo '            2. will try to revert *mostly everything* installed using install.sh, so it'\''s pretty destructive'
echo '            3. has not beed tested, use at your own risk.'
echo '            4. will show all commands that it runs.'
echo '            5. should be run from its folder.'
echo 'Ctrl+C to exit. Enter to continue.'
read

##############################################################################################################################

# Undo Step 3: Removing copied config and local folders
echo 'Removing copied config and local folders...'
echo 'rm -rf "$HOME/.config/ags" "$HOME/.config/fish" "$HOME/.config/frontconfig" "$HOME/.config/foot" "$HOME/.config/fuzzel" "$HOME/.config/gtklock" "$HOME/.config/hypr" "$HOME/.config/mpv" "$HOME/.config/swaylock" "$HOME/.config/wlogout" "$HOME/.config/starship.toml" '
rm -rf "$HOME/.config/ags" "$HOME/.config/fish" "$HOME/.config/frontconfig" "$HOME/.config/foot" "$HOME/.config/fuzzel" "$HOME/.config/gtklock" "$HOME/.config/hypr" "$HOME/.config/mpv" "$HOME/.config/swaylock" "$HOME/.config/wlogout" "$HOME/.config/starship.toml"
echo 'rm -rf "$HOME/.local/bin/fuzzel-emoji" "$HOME/.config/rubyshot"'
rm -rf "$HOME/.local/bin/fuzzel-emoji" "$HOME/.config/rubyshot"

##############################################################################################################################

# Undo Step 2: Uninstall AGS - Disabled for now, check issues
# echo 'Uninstalling AGS...'
# sudo meson uninstall -C ~/ags/build
# rm -rf ~/ags

##############################################################################################################################

# Undo Step 1: Remove added user from video and input groups and remove yay packages
echo 'Removing user from video and input groups and removing packages...'
user=$(whoami)
echo 'sudo deluser "$user" video'
sudo deluser "$user" video
echo 'sudo deluser "$user" input'
sudo deluser "$user" input
echo 'User removed from video and input groups.'

##############################################################################################################################

# Removing installed yay packages and dependencies
echo 'yay -Rns adw-gtk3-git brightnessctl cava foot fuzzel gjs gojq gradience-git grim gtk-layer-shell gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git libdbusmenu-gtk3 plasma-browser-integration playerctl python-build python-material-color-utilities python-poetry python-pywal ripgrep sassc slurp starship swayidle swaylock swww tesseract ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-space-mono-nerd typescript webp-pixbuf-loader wl-clipboard wlogout yad ydotool'
yay -Rns adw-gtk3-git brightnessctl cava foot fuzzel gjs gojq gradience-git grim gtk-layer-shell gtklock gtklock-playerctl-module gtklock-powerbar-module gtklock-userinfo-module hyprland-git lexend-fonts-git libdbusmenu-gtk3 plasma-browser-integration playerctl python-build python-material-color-utilities python-poetry python-pywal ripgrep sassc slurp starship swayidle swaylock swww tesseract ttf-jetbrains-mono-nerd ttf-material-symbols-variable-git ttf-space-mono-nerd typescript webp-pixbuf-loader wl-clipboard wlogout yad ydotool


echo 'Uninstall Complete.'
