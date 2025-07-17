#!/bin/bash

# Exit immediately on command error inside functions
set -e

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Script paths
INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"
FONTS_SCRIPT="$SCRIPT_DIR/fonts.sh"
MANUAL_HELPER_SCRIPT="$SCRIPT_DIR/../manual-install-helper.sh"

# Ask if user wants to exit
ask_exit() {
    read -n1 -r -p "$(echo -e "${YELLOW}Do you want to exit the installer? (y/N): ${NC}")" answer
    echo
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
    fi
}

# Run script with or without sudo
run_script() {
    local script="$1"
    local sudo_flag="$2"

    if [[ "$sudo_flag" == "sudo" ]]; then
        echo -e "${YELLOW}Running $script with sudo...${NC}"
        sudo bash "$script"
    else
        echo -e "${YELLOW}Running $script as current user...${NC}"
        bash "$script"
    fi
    echo -e "${GREEN}✅ $script completed successfully.${NC}"
}

# Force copy of dotfiles (no exclusions)
copy_dotfiles() {
    echo -e "${YELLOW}Copying dotfiles to ~/.config and ~/.local (no exclusions)...${NC}"
    cp -Rf .config/* ~/.config/ || { echo -e "${RED}❌ Failed copying .config${NC}"; exit 1; }
    cp -Rf .local/* ~/.local/ || { echo -e "${RED}❌ Failed copying .local${NC}"; exit 1; }
    echo -e "${GREEN}✅ Dotfiles copied successfully.${NC}"
}

# dotfiles copy (skip custom/user files if already present)
copy_dotfiles_smart() {
    echo -e "${YELLOW}Copying dotfiles to ~/.config...${NC}"
    
    mkdir -p ~/.config ~/.local

    RSYNC_EXCLUDES=()
    [[ -e ~/.config/hypr/custom ]] && RSYNC_EXCLUDES+=(--exclude 'hypr/custom/**')
#    [[ -e ~/.config/hypr/hyprland.conf ]] && RSYNC_EXCLUDES+=(--exclude 'hypr/hyprland.conf')
    [[ -e ~/.config/kde-material-you-colors/config.conf ]] && RSYNC_EXCLUDES+=(--exclude 'kde-material-you-colors/config.conf')
    [[ -e ~/.config/hypr/hypridle.conf ]] && RSYNC_EXCLUDES+=(--exclude 'hypr/hypridle.conf')
    
    rsync -a "${RSYNC_EXCLUDES[@]}" .config/ ~/.config/ \
        || { echo -e "${RED}❌ Failed copying to ~/.config${NC}"; exit 1; }

    rsync -a .local/ ~/.local/ \
        || { echo -e "${RED}❌ Failed copying to ~/.local${NC}"; exit 1; }

    fix_gtk_ownership || { echo -e "${RED}❌ Failed: fix_gtk_ownership${NC}"; exit 1; }

    echo -e "${GREEN}✅ Dotfiles copied successfully.${NC}"
}

# Full install: all scripts + dotfiles
run_full_install() {
    echo -e "${YELLOW}Starting full installation...${NC}"
    run_script "$INSTALL_SCRIPT" sudo || { echo -e "${RED}❌ Failed: $INSTALL_SCRIPT${NC}"; exit 1; }
    run_script "$FONTS_SCRIPT" ""     || { echo -e "${RED}❌ Failed: $FONTS_SCRIPT${NC}"; exit 1; }
    run_script "$MANUAL_HELPER_SCRIPT" "" || { echo -e "${RED}❌ Failed: $MANUAL_HELPER_SCRIPT${NC}"; exit 1; }
    copy_dotfiles_smart || { echo -e "${RED}❌ Failed: copy_dotfiles_smart${NC}"; exit 1; }
    fix_gtk_ownership || { echo -e "${RED}❌ Failed: fix_gtk_ownership${NC}"; exit 1; }
    echo -e "${GREEN}🎉 Full installation completed successfully! You can now reboot and select Hyprland at login.${NC}"
}

# fix themes
fix_gtk_ownership() {
    local user=$(whoami)
    echo "Changing ownership of GTK 4.0 config files to user: $user"

    if [ -e ~/.config/gtk-4.0 ]; then
        sudo chown "$user" ~/.config/gtk-4.0
    fi

    if [ -f ~/.config/gtk-4.0/gtk.css ]; then
        sudo chown "$user" ~/.config/gtk-4.0/gtk.css
    fi

    if [ -f ~/.config/gtk-4.0/gtk-dark.css ]; then
        sudo chown "$user" ~/.config/gtk-4.0/gtk-dark.css
    fi

    if [ -d ~/.local/state/quickshell ]; then
        sudo chown -R "$user":"$user" ~/.local/state/quickshell
        sudo chmod -R u+rw ~/.local/state/quickshell
    fi

    if [ -d ~/.config/Kvantum ]; then
        sudo chown -R "$user":"$user" ~/.config/Kvantum
        sudo chmod -R u+rw ~/.config/Kvantum
    fi
}

# Menu loop
while true; do
    echo -e "\n${YELLOW}Select an option:${NC}"
    echo "1) Full install/Update"
    echo "2) Exit"
    echo ""
    echo -e "\n${YELLOW}Partial Installations (be sure of what you are doing):${NC}"
    echo "3) Run manual-install-helper.sh"
    echo "4) Force Copy ~/.config and ~/.local (no exclusions)"
    echo "5) Install Dependencies"
    echo "6) Update config files with exclusions"
    echo "7) Install/Update Fonts"
    echo ""

    read -rp "Enter your choice [1-7]: " choice

    case "$choice" in
        1)
            run_full_install
            exit 0
            ;;
        2)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        3)
            run_script "$MANUAL_HELPER_SCRIPT" "" || { echo -e "${RED}❌ Failed: $MANUAL_HELPER_SCRIPT${NC}"; }
            ask_exit
            ;;
        4)
            copy_dotfiles
            ask_exit
            ;;
        5)
            run_script "$INSTALL_SCRIPT" sudo || { echo -e "${RED}❌ Failed: $INSTALL_SCRIPT${NC}"; }
            ask_exit
            ;;
        6)
            copy_dotfiles_smart
            ask_exit
            ;;
        7)
            run_script "$FONTS_SCRIPT" "" || { echo -e "${RED}❌ Failed: $FONTS_SCRIPT${NC}"; }
            ask_exit
            ;;
        *)
            echo -e "${RED}Invalid option. Please enter a number from 1 to 6.${NC}"
            ;;
    esac
done