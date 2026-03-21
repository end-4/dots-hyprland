#!/bin/bash
# Extra files to copy during ./setup install
#
# HOW TO USE:
#   Place files you want to copy in dots/custom/files/
#   Then uncomment and edit the rsync_dir line below.
#
#   Example structure:
#   dots/custom/files/.config/mpv.conf
#   dots/custom/files/.local/share/myapp/data
#
#   When the rsync line runs, it copies dots/custom/files/* to $HOME/
#   So ~/.config/mpv.conf and ~/.local/share/myapp/data would be created.
#
# HELPER FUNCTIONS:
#   cp_file <source> <destination>  - Copy a single file
#   rsync_dir <source_dir> <dest_dir> - Copy entire directory recursively
#
# IMPORTANT:
#   - Keep the function name and structure intact
#   - Uncomment lines by removing the leading #
#   - Test your paths exist before running install

custom_files() {
    # Example: uncomment and run these lines to copy files from dots/custom/files/
    # local src_dir="dots/custom/files"
    # local dest_dir="$HOME"
    # rsync_dir "$src_dir" "$dest_dir"

    # Or copy specific files:
    # cp_file "dots/custom/files/.config/app.conf" "$HOME/.config/app.conf"

    # Add your custom file operations below:

    # Leave this no-op command to prevent syntax errors
    :
}
