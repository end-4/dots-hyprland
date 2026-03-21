#!/bin/bash
# Extra commands to run during ./setup install
#
# HOW TO USE:
#   Add ONE command per line AFTER the # comment marker.
#   Do NOT remove the function name or change its structure.
#
#   Example:
#   custom_commands() {
#       # mkdir -p ~/.local/share/myapp
#       # systemctl --user enable myservice
#       # chmod +x ~/.local/bin/myscript
#   }
#
# IMPORTANT:
#   - One command per line
#   - Keep the # prefix on each line
#   - Commands run as your user (not root)
#   - You can use pipes, redirects, and compound commands

custom_commands() {
    # Example: uncomment the line below to create a directory
    # mkdir -p ~/.local/share/myapp

    # Add your commands below, one per line, keeping the # prefix:
    # systemctl --user enable myservice
    # chmod +x ~/.local/bin/myscript
}
