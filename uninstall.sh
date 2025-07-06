#!/usr/bin/env bash
cd "$(dirname "$0")"
source ./scriptdata/environment-variables
source ./scriptdata/functions
prevent_sudo_or_root

# Define allowed base directories for deletion.
# Resolve environment variables to absolute paths.
ALLOWED_DELETE_BASE_DIRS=()
if [ -n "$XDG_CONFIG_HOME" ]; then ALLOWED_DELETE_BASE_DIRS+=("$(realpath "$XDG_CONFIG_HOME")"); fi
if [ -n "$XDG_DATA_HOME" ]; then ALLOWED_DELETE_BASE_DIRS+=("$(realpath "$XDG_DATA_HOME")"); fi
if [ -n "$XDG_BIN_HOME" ]; then ALLOWED_DELETE_BASE_DIRS+=("$(realpath "$XDG_BIN_HOME")"); fi
if [ -n "$XDG_CACHE_HOME" ]; then ALLOWED_DELETE_BASE_DIRS+=("$(realpath "$XDG_CACHE_HOME")"); fi
if [ -n "$XDG_STATE_HOME" ]; then ALLOWED_DELETE_BASE_DIRS+=("$(realpath "$XDG_STATE_HOME")"); fi
# Add other specific parent directories if needed, e.g., user's home for specific dotfiles if not covered by XDG vars
ALLOWED_DELETE_BASE_DIRS+=("$(realpath ~)/.local/share") # Example, adjust as needed
ALLOWED_DELETE_BASE_DIRS+=("$(realpath ~)/.config") # Example, adjust as needed
ALLOWED_DELETE_BASE_DIRS+=("$(realpath ~)/.cache") # Example, adjust as needed
ALLOWED_DELETE_BASE_DIRS+=("$(realpath ~)/.local/state") # Example, adjust as needed
ALLOWED_DELETE_BASE_DIRS+=("$(realpath ~)/.local/bin") # Example, adjust as needed


# Function to safely remove files and directories
safe_rm() {
  local target_path="$1"
  local use_sudo="${2:-no_sudo}" # Default to no sudo

  # Resolve to absolute path
  local absolute_target_path
  absolute_target_path=$(realpath -m "$target_path" 2>/dev/null)

  if [ -z "$absolute_target_path" ]; then
    echo -e "[$0]: \e[33mWarning:\e[0m Path '$target_path' does not exist or cannot be resolved. Skipping."
    return
  fi

  # Check if the path is within allowed directories
  local allowed=false
  for base_dir in "${ALLOWED_DELETE_BASE_DIRS[@]}"; do
    if [[ "$absolute_target_path" == "$base_dir"* ]]; then
      allowed=true
      break
    fi
  done

  if [ "$allowed" = false ]; then
    echo -e "[$0]: \e[31mError:\e[0m Path '$absolute_target_path' is not in an allowed directory for deletion. Skipping."
    return
  fi

  # Confirmation
  read -p "Are you sure you want to delete '$absolute_target_path'? (y/N): " confirmation
  if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
    echo -e "[$0]: \e[33mSkipped deletion of '$absolute_target_path'.\e[0m"
    return
  fi

  echo -e "[$0]: \e[32mNow executing:\e[0m"
  if [ "$use_sudo" = "sudo" ]; then
    echo -e "\e[32msudo rm -rf \"$absolute_target_path\"\e[0m"
    sudo rm -rf "$absolute_target_path"
  else
    echo -e "\e[32mrm -rf \"$absolute_target_path\"\e[0m"
    rm -rf "$absolute_target_path"
  fi
}

function v() {
  echo -e "[$0]: \e[32mNow executing:\e[0m"
  echo -e "\e[32m$@\e[0m"
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
printf '\e[36mRemoving copied config and local folders...\n\e[97m'

for i in ags fish fontconfig foot fuzzel hypr mpv wlogout "starship.toml" rubyshot
  do safe_rm "$XDG_CONFIG_HOME/$i"
done
for i in "glib-2.0/schemas/com.github.GradienceTeam.Gradience.Devel.gschema.xml" "gradience"
  do safe_rm "$XDG_DATA_HOME/$i"
done
safe_rm "$XDG_BIN_HOME/fuzzel-emoji"
safe_rm "$XDG_CACHE_HOME/ags"
safe_rm "$XDG_STATE_HOME/ags" sudo # Note: sudo is passed as the second argument

##############################################################################################################################

# Undo Step 2: Uninstall AGS - Disabled for now, check issues
# echo 'Uninstalling AGS...'
# sudo meson uninstall -C ~/ags/build
# rm -rf ~/ags

##############################################################################################################################

# Undo Step 1: Remove added user from video, i2c, and input groups and remove yay packages
printf '\e[36mRemoving user from video, i2c, and input groups and removing packages...\n\e[97m'
user=$(whoami)
v sudo gpasswd -d "$user" video
v sudo gpasswd -d "$user" i2c
v sudo gpasswd -d "$user" input
v sudo rm /etc/modules-load.d/i2c-dev.conf

##############################################################################################################################
read -p "Do you want to uninstall packages used by the dotfiles?\nCtrl+C to exit, or press Enter to proceed"

# Removing installed yay packages and dependencies
v yay -Rns illogical-impulse-{agsv1,audio,backlight,basic,bibata-modern-classic-bin,fonts-themes,gnome,gtk,hyprland,microtex-git,oneui4-icons-git,portal,python,screencapture,widgets} plasma-browser-integration

printf '\e[36mUninstall Complete.\n\e[97m'
