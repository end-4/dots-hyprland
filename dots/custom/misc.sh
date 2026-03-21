#!/bin/bash
# Miscellaneous custom items during ./setup install
#
# HOW TO USE:
#   Put anything that doesn't fit into deps, files, or commands.
#   Do NOT remove the function name or change its structure.
#
#   Example:
#   custom_misc() {
#       # ln -sf "$(pwd)/dots/custom/scripts/my-script.sh" "$HOME/.local/bin/my-script"
#       # chmod +x "$HOME/.local/bin/my-script"
#   }
#
# IMPORTANT:
#   - Keep the function name and structure intact
#   - Commands run as your user (not root)

custom_misc() {
    # Example: uncomment to create a symlink to a script
    # ln -sf "$(pwd)/dots/custom/scripts/my-script.sh" "$HOME/.local/bin/my-script"

    # Example: uncomment to make a script executable
    # chmod +x "$HOME/.local/bin/my-script"

    # Add your miscellaneous customizations below:
}
