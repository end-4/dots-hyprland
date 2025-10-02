#!/usr/bin/env bash
cd "$(dirname "$0")"
source ./scriptdata/lib/environment-variables.sh
source ./scriptdata/lib/functions.sh
prevent_sudo_or_root

function v() {
  echo -e "[$0]: ${STY_GREEN}Now executing:${STY_RESET}"
  echo -e "${STY_GREEN}$@${STY_RESET}"
  "$@"
}

printf 'Hi there!\n'
printf 'This script 1. will uninstall [end-4/dots-hyprland > illogical-impulse] dotfiles\n'
printf '            2. will try to revert *mostly everything* installed using install.sh, so it'\''s pretty destructive\n'
printf '            3. has not been tested, use at your own risk.\n'
printf '            4. will show all commands that it runs.\n'
printf 'Ctrl+C to exit. Enter to continue.\n'
read -r
set -e
##############################################################################################################################

# Undo Step 3: Removing copied config and local folders
printf "${STY_CYAN}Removing copied config and local folders...\n${STY_RESET}"

for i in ags fish fontconfig foot fuzzel hypr mpv wlogout "starship.toml" rubyshot
  do v rm -rf "$XDG_CONFIG_HOME/$i"
done
for i in "glib-2.0/schemas/com.github.GradienceTeam.Gradience.Devel.gschema.xml" "gradience"
  do v rm -rf "$XDG_DATA_HOME/$i"
done
v rm -rf "$XDG_BIN_HOME/fuzzel-emoji"
v rm -rf "$XDG_CACHE_HOME/ags"
v sudo rm -rf "$XDG_STATE_HOME/ags"

##############################################################################################################################

# Undo Step 2: Uninstall AGS - Disabled for now, check issues
# echo 'Uninstalling AGS...'
# sudo meson uninstall -C ~/ags/build
# rm -rf ~/ags

##############################################################################################################################

# Undo Step 1: Remove added user from video, i2c, and input groups and remove yay packages
printf "${STY_CYAN}Removing user from video, i2c, and input groups and removing packages...\n${STY_RESET}"
user=$(whoami)
v sudo gpasswd -d "$user" video
v sudo gpasswd -d "$user" i2c
v sudo gpasswd -d "$user" input
v sudo rm /etc/modules-load.d/i2c-dev.conf

##############################################################################################################################
read -p "Do you want to uninstall the illogical-impulse-* meta packages (Arch Linux only)?
Ctrl+C to exit, or press Enter to proceed" p

# Removing installed yay packages and dependencies
v yay -Rns illogical-impulse-{agsv1,audio,backlight,basic,bibata-modern-classic-bin,fonts-themes,gnome,gtk,hyprland,microtex-git,oneui4-icons-git,portal,python,screencapture,widgets} plasma-browser-integration

printf "${STY_CYAN}Uninstall Complete.\n${STY_RESET}"
