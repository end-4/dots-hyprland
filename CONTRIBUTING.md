# Contributing

- Please, please, please, make multiple PRs if you have many features/fixes, and don't shove your personal changes along with the PR, including changed defaults
- I can accept features I do not personally want, but in that case I will ask you to make it configurable/optionally loaded
- If you want to start working on something big to contribute, it might be a good idea to ask first to not waste your effort (but if you've already done it for yourself, it doesn't hurt to submit)

# Code details

## Dynamic loading

- If something's not always necessary, especially when guarded by a config option to enable/disable, put it in a `Loader`. One tip with `Loader`s is sometimes you will need to declare positioning properties (like `anchors`) in the `Loader`, not the `sourceComponent`

## Practical concerns

- Make sure what you add does not require significant resources for a minor purpose or harm usability just for the sake of looking nice. The dotfiles must remain practical for daily driving.
- If there is something really fancy and impractical anyway, add a config option for it and make sure it's disabled by default. 

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
