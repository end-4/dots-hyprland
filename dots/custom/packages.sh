#!/bin/bash
# Extra packages to install during ./setup install
#
# HOW TO USE:
#   Add ONE package name per line AFTER the # comment marker.
#   Do NOT remove the function name or change its structure.
#
#   Example:
#   custom_packages() {
#       # firefox
#       # vlc
#       # thunderbird
#   }
#
# IMPORTANT:
#   - One package per line
#   - Keep the # prefix on each line
#   - Package names should work across distros (install_cmds handles distro detection)

custom_packages() {
    # Example: uncomment the line below to install firefox
      zen-browser
      vlc-plugins-all
      claude
      

    # Add your packages below, one per line, keeping the # prefix:
    # example-package
    # another-package

    # Leave this no-op command to prevent syntax errors
    :
}
