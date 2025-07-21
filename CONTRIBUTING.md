# Contributing

- I can accept features I do not personally want, but in that case I will ask you to make it configurable/optionally loaded
- If you want to add new stuff, it's a good idea to ask me first to not waste your work
- Please make multiple PRs if you have many features/fixes

# Setting up

Assumption: you have an Arch(-based) Linux system

## Complete

_might not be necessary depending on what you change, but this is recommended_

- [Install](https://end-4.github.io/dots-hyprland-wiki/en/ii-qs/01setup/) the dotfiles (if you don't wanna replace your stuff completely, do it on a new user)
- Make changes, copy changes to a fork, PR

## Partially working shell

_most stuff in the shell will work but not everything_

- Install Hyprland and the development version of Quickshell (`yay -S hyprland quickshell-git`)
- Copy `.config/quickshell` folder to your home directory

## Extra setup for Quickshell
- Quickshell-specific LSP setup: Run `touch ~/.config/quickshell/ii/.qmlls.ini` for proper LSP support
- Hint for VSCode: Get the official "Qt Qml" extension, go to its settings and change custom exe path to `/usr/bin/qmlls6`

# Running

- Launch Hyprland (not the "uwsm-managed" one)
- For the shell:
  - Open `~/.config/quickshell/ii` in your code editor
  - In a terminal run `pkill qs; qs -c ii` to start the shell in the terminal (for logs)
  - Make edits in the opened folder. Changes are reloaded live.
