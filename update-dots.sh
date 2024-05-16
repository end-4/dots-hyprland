#!/bin/bash
# This script updates the dotfiles by fetching the latest version from the Git repository and then replacing files
# that have not been modified by the user to preserve changes. The remaining files will be replaced with the new ones.

set -euo pipefail
cd "$(dirname "$0")"
export base="$(pwd)"

# Define colors
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
MAGENTA="\033[0;35m"
RESET="\033[0m"

# Define paths to update
folders=(".config" ".local")
excludes=(".config/hypr/custom" ".config/ags/user_options.js" ".config/hypr/hyprland.conf")

get_checksum() {
    # Get the checksum of a specific file
    local file="$1"
    md5sum "$file" | awk '{print $1}'
}

file_in_excludes() {
    # Check if a file is in the exclude_folders
    local file="$1"
    for exc in "${excludes[@]}"; do
        if [[ $file == "$exc"* ]]; then
            return 0
        fi
    done
    return 1
}

# Greetings!
cat << 'EOF'
###################################################################################################
|                                                                                                 |
|  Hi there!                                                                                      |
|                                                                                                 |
|  This script will update your dotfiles (.config, .local, etc) by retrieving the latest version  |
|  from the Git repository and then replacing the old config files with the updated ones.         |
|  To preserve your customizations, it will ask you if you wanna keep some  modified              |
|  files untouched.                                                                               |
|                                                                                                 |
###################################################################################################
EOF

read -rp "Do you want to continue? [Y/n] " REPLY
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${RED}Exiting.${RESET}"
    exit 0
fi

# End of Greetings

current_branch=$(git rev-parse --abbrev-ref HEAD)

# fetch the latest version of the repository
if ! git fetch; then
    echo -e "${RED}Failed to fetch the latest version of the repository. Exiting.${RESET}"
    exit 1
fi

# Check if there are any changes
if [[ $(git rev-list HEAD...origin/"$current_branch" --count) -eq 0 ]]; then
    echo -e "${GREEN}Repository is already up-to-date. Do not run git pull before this script. Exiting.${RESET}"
    exit 0
fi
echo -e "${CYAN}Excluding files and folders: ${excludes[@]}${RESET}"

# Then check which files have been modified by the user since the last update to preserve user configurations
modified_files=()

# Find all files in the specified folders and their subfolders
while IFS= read -r -d '' file; do
    # If the file is not in the home directory, skip it
    if [[ ! -f "$HOME/$file" ]] || file_in_excludes "$file"; then
        echo -e "${YELLOW}Skipping $file${RESET}"
        continue
    fi
    
    # Calculate checksums
    base_checksum=$(get_checksum "$base/$file")
    home_checksum=$(get_checksum "$HOME/$file")
    
    # Compare checksums and add to modified_files if necessary
    if [[ $base_checksum != $home_checksum ]]; then
        modified_files+=("$file")
    fi
done < <(find "${folders[@]}" -type f -print0)

echo

# Output all modified files
if [[ ${#modified_files[@]} -gt 0 ]]; then
    echo -e "${MAGENTA}The following files have been modified since the last update:${RESET}"
    for file in "${modified_files[@]}"; do
        echo -e "${BLUE}$file${RESET}"
    done
else
    read -rp "No files found that have been modified since the last update. All files will be replaced. Are you sure you want to continue? [Y/n] " REPLY
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${RED}Exiting.${RESET}"
        exit 0
    fi
fi

cat << 'EOF'
Do you want to keep these files untouched?
[Y] Yes, keep them.
[n] No, replace them.
[i] Check the files individually.
EOF
read -rp "Answer: " REPLY
echo

case $REPLY in
    [Nn])
        echo -e "${RED}Replacing all files.${RESET}"
        modified_files=()
    ;;
    [Ii])
        new_modified_files=()
        replaced_files=()
        for file in "${modified_files[@]}"; do
            read -rp "Do you want to keep $file untouched? [Y/n] " REPLY
            echo
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                replaced_files+=("$file")
            else
                new_modified_files+=("$file")
            fi
        done
        modified_files=("${new_modified_files[@]}")
        echo -e "${CYAN}_____________________________________________________${RESET}"
        echo -e "${MAGENTA}These User configured/modified files will be kept:${RESET}"
        for file in "${modified_files[@]}"; do
            echo -e "${BLUE}$file${RESET}"
        done
        echo -e "${CYAN}_____________________________________________________${RESET}"
        echo -e "${MAGENTA}These User configured/modified files will be replaced:${RESET}"
        for file in "${replaced_files[@]}"; do
            echo -e "${BLUE}$file${RESET}"
        done
        echo -e "${CYAN}_____________________________________________________${RESET}"
        read -rp "Do you want to continue? [y/N] " REPLY
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}Exiting...${RESET}"
            exit 0
        fi
    ;;
    *)
        echo -e "${GREEN}Keeping every modified file${RESET}"
    ;;
esac

# Update the repository
if ! git pull; then
    echo -e "${RED}Git pull failed. Consider recloning the project or resolving conflicts manually.${RESET}"
    read -rp "Should I clone the repository to a temporary folder in cache and copy the files from there? [y/N] " REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Exiting...${RESET}"
        exit 1
    fi
    
    mkdir -p ./cache
    temp_folder=$(mktemp -d -p ./cache)
    git clone https://github.com/end-4/dots-hyprland/ --depth=1 "$temp_folder"
    # Replace the existing dotfiles with the new ones
    for folder in "${folders[@]}"; do
        find "$temp_folder/$folder" -print0 | while IFS= read -r -d '' file; do
            file=${file//$temp_folder\//}
            if [[ -d "$temp_folder/$file" ]]; then
                mkdir -p "$HOME/$file"
            fi
            if [[ -f "$temp_folder/$file" ]] && ! file_in_excludes "$file" && [[ ! " ${modified_files[*]} " =~ " $file " ]]; then
                destination="$HOME/$file"
                echo -e "${BLUE}Replacing $destination ...${RESET}"
                mkdir -p "$(dirname "$destination")"
                cp -f "$temp_folder/$file" "$destination"
            fi
        done
    done
    echo -e "${GREEN}New dotfiles have been copied. Cleaning up temporary folder.${RESET}"
    rm -rf "$temp_folder"
    exit 0
fi

# Replace unmodified files
for folder in "${folders[@]}"; do
    find "$folder" -print0 | while IFS= read -r -d '' file; do
        if [[ -d "$file" ]]; then
            mkdir -p "$HOME/$file"
        fi
        if [[ -f "$file" ]] && ! file_in_excludes "$file" && [[ ! " ${modified_files[*]} " =~ " $file " ]]; then
            destination="$HOME/$file"
            echo -e "${BLUE}Replacing \"$destination\" ...${RESET}"
            mkdir -p "$(dirname "$destination")"
            cp -f "$base/$file" "$destination"
        fi
    done
done
