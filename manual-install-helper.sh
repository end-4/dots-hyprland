#!/usr/bin/env bash
#
# This script is for installing/updating some "packages" for non-Arch users.
#

cd "$(dirname "$0")"
export base="$(pwd)"
source ./scriptdata/environment-variables
source ./scriptdata/functions
source ./scriptdata/installers
prevent_sudo_or_root

if command -v pacman >/dev/null 2>&1;then printf "${COLOR_RED}[$0]: pacman found, it seems that the system is ArchLinux or Arch-based distro. Aborting...${COLOR_RESET}\n";exit 1;fi
v install-Rubik
v install-Gabarito
v install-OneUI
v install-bibata
v install-MicroTeX
v install-uv
v install-python-packages

if [[ -z "${ILLOGICAL_IMPULSE_VIRTUAL_ENV}" ]]; then
  printf "\n${COLOR_RED}[$0]: \!! Important \!! : Please ensure environment variable ${COLOR_RESET} \$ILLOGICAL_IMPULSE_VIRTUAL_ENV ${COLOR_RED} is set to proper value (by default \"~/.local/state/ags/.venv\"), or AGS config will not work. We have already provided this configuration in ~/.config/hypr/hyprland/env.conf, but you need to ensure it is included in hyprland.conf, and also a restart is needed for applying it.${COLOR_RESET}\n"
fi
