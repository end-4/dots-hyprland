#!/usr/bin/bash

func_printpipe() {
    echo '  |  '
}

func_printseparator() {
    echo ''
    echo ' [+]  --------------------------------------------'
    echo ''
}

func_home_install() {
    if [ "$1" == "" ]; then
        return  # Do not wipe home folder
    fi
    func_printpipe
    echo ' [>_] rm -rf '"${HOME:?}/${1:?}"
    rm -rf "${HOME:?}/${1:?}"
    echo ' [>_] cp -r '"./${1:?}" "${HOME:?}/${1:?}"
    cp -r "./${1:?}" "${HOME:?}/${1:?}"
    func_printpipe
}

func_welcome() {
    echo ' [i]  WARNING: Run this script IN ITS FOLDER, or it will not work!'
    func_printseparator
    echo ' [i]  Using install scripts might mess up your setup without'
    echo '      proper understanding.'
    echo '      However, if you wish, we will proceed.'
    echo ' [i]  I'\''ll create a backup of your .config folder'
    echo '      and will let you select what to copy from these dotfiles.'
    echo '      Every command used will be shown.'
    func_printseparator
    echo -n ' [?]  Shall we begin? [Y/n] '
    read -r userInput
    if [ "$userInput" == "y" ] || [ "$userInput" == "Y" ] || [ "$userInput" == "" ]; then
        echo " [i]  Let's go."
        func_printseparator
    else
        printf " [i]  Aborted.\n"
        exit 0
    fi
}

func_backup() {
    echo ' [?]  We will now backup your .config folder. '
    echo '  |   Hit Enter to proceed.'
    echo '  +-  Else, type "I understand the risk of not backing up."'
    echo -n ' [>>>]  '
    read -r userInput
    if [ "$userInput" == "I understand the risk of not backing up." ]; then
        echo ' [i]  Got it. You understand the risk of having no backup and will not backup.'
    else
        echo ' [i]  Alright.'
        echo ' [>_] cp -r "$HOME/.config" "$HOME/.config_BACKUP"'
        cp -r "$HOME/.config" "$HOME/.config_BACKUP"
        echo ' [i]  Backup done.'
    fi
    func_printseparator
}

func_install_config() {
    echo ' [?]  Install eww config? '
    echo '      This is for the bar and menus. '
    echo -n '      [Y/n] '
    read -r userInput
    if [ "$userInput" == "y" ] || [ "$userInput" == "Y" ] || [ "$userInput" == "" ]; then
        func_home_install ".config/eww/"
    else
        printf " [i]  Skipping eww config installation.\n"
    fi
    
    echo ' [?]  Install Hyprland config?'
    echo '      (You can select many. "k e" will install both keybinds and execs)'
    echo -n '      [A]ll/[k]eybinds/[e]xecs/[n]one '
    read -r userInput
    if [ "$userInput" == "A" ] || [ "$userInput" == "a" ] || [ "$userInput" == "" ]; then
        func_home_install ".config/hypr/"
    else
        if [[ "$userInput" == *"K"* ]] || [[ "$userInput" == *"k"* ]]; then
            func_home_install ".config/hypr/keybinds.conf"
        fi
        if [[ "$userInput" == *"E"* ]] || [[ "$userInput" == *"e"* ]]; then
            func_home_install ".config/hypr/execs.conf"
        fi

        if [[ "$userInput" == "N" ]] || [[ "$userInput" == "n" ]]; then
            printf " [-]  Skipping Hyprland config installation.\n"
        fi
    fi
    
    echo -n ' [?]  Install GTK theme? This is for appearance of GTK apps [Y/n] '
    read -r userInput
    if [ "$userInput" == "y" ] || [ "$userInput" == "Y" ] || [ "$userInput" == "" ]; then
        func_home_install ".config/gtk-3.0/"
        func_home_install ".config/gtk-4.0/"
    else
        printf " [-]  Skipping GTK theme installation.\n"
    fi
    
    echo -n ' [?]  Install Starship prompt? [Y/n] '
    read -r userInput
    if [ "$userInput" == "y" ] || [ "$userInput" == "Y" ] || [ "$userInput" == "" ]; then
        func_home_install ".config/starship.toml"
    else
        printf " [-]  Skipping Starship prompt installation.\n"
    fi
    
    echo -n ' [?]  Install dunst config? This is for notification style [Y/n] '
    read -r userInput
    if [ "$userInput" == "y" ] || [ "$userInput" == "Y" ] || [ "$userInput" == "" ]; then
        func_home_install ".config/dunst/"
    else
        printf " [-]  Skipping dunst config installation.\n"
    fi
}

func_install_local() {
    echo -n ' [?]  Install bundled fonts? [Y/n] '
    read -r userInput
    if [ "$userInput" == "y" ] || [ "$userInput" == "Y" ] || [ "$userInput" == "" ]; then
        func_home_install ".local/share/fonts/"
    else
        printf " [-]  Skipping font installation.\n"
    fi

    echo ' [?]  Install icon packs?'
    echo '      (requires root so that geticons would run normally)'
    echo -n '      [Y/n] '
    read -r userInput
    if [ "$userInput" == "y" ] || [ "$userInput" == "Y" ] || [ "$userInput" == "" ]; then
        sudo cp -r ./.local/share/icons/ /usr/share/
    else
        printf " [-]  Skipping icon installation.\n"
    fi
}


func_welcome
func_backup
func_install_config
func_install_local

