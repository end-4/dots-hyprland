#!/bin/bash
# This script updates the dotfiles by fetching the latest version from the Git repository and then replacing files
# that have not been modified by the user to preserve changes. The remaining files will be replaced with the new ones.

source ./scriptdata/environment-variables

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
folders=(".config" ".local/bin" ".local/share" ".local/state")
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

get_destination() {
	# Get the correct destination of the file based on XDG base dirs
	local file="$1"
	local localdir="$(echo $file | cut -d/ -f1-2)"
	local everything_else="$(echo $file | cut -d/ -f3-)"
	# Check if path is config
	if [ "$(echo $file | cut -d/ -f1)" = ".config" ]; then
		printf "$XDG_CONFIG_HOME/$(echo $file | cut -d/ -f2-)"

	# Local directory
	elif [ "$localdir" = ".local/bin" ]; then
		printf "$XDG_BIN_HOME/$everything_else"
	
	# There are no files in either of the following right now, but putting it here just in case as .local was specified
	elif [ "$localdir" = ".local/share" ]; then
		printf "$XDG_DATA_HOME/$everything_else"
	elif [ "$localdir" = ".local/state" ]; then
		printf "$XDG_STATE_HOME/$everything_else"
	fi
}

# Greetings!
cat << 'EOF'
###################################################################################################
|                                                                                                 |
|  Hi there!                                                                                      |
|                                                                                                 |
|  This script will update your dotfiles (.config, .local, etc) by retrieving the latest version  |
|  from the Git repository and then replacing the old config files with the updated ones.         |
|  To preserve your customizations, it will ask you if you wanna keep some customized             |
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
    echo -e "${RED}Failed to fetch the latest version of the repository. Exiting...${RESET}"
    exit 1
fi

# Check if there are any changes
if [[ $(git rev-list HEAD...origin/"$current_branch" --count) -eq 0 ]]; then
    echo -e "${GREEN}Repository is already up-to-date. Do not run git pull before this script. Exiting...${RESET}"
    exit 0
fi
echo -e "${CYAN}Excluding files and folders that remain untouched:${RESET} ${excludes[@]}"

# Then check which files have been customized by the user since the last update to preserve user configurations
modified_files=()

# Find all files in the specified folders and their subfolders
while IFS= read -r -d '' file; do
    # If the file is not in the home directory, skip it
    if [[ ! -f "$(get_destination $file)" ]] || file_in_excludes "$file"; then
        echo -e "${YELLOW}Skipping $file${RESET}"
        continue
    fi
    
    # Calculate checksums
    base_checksum=$(get_checksum "$base/$file")
    home_checksum=$(get_checksum "$(get_destination $file)")
    
    # Compare checksums and add to modified_files if necessary
    if [[ $base_checksum != $home_checksum ]]; then
        modified_files+=("$file")
    fi
done < <(find "${folders[@]}" -type f -print0)

echo

# Output all modified files
if [[ ${#modified_files[@]} -gt 0 ]]; then
    echo -e "${MAGENTA}Customized Files detected: ${RESET}The following files have been customized by you or your system:"
    for file in "${modified_files[@]}"; do
        echo -e "${BLUE}$file${RESET}"
    done
else
    read -rp "${YELLOW}No files detected that have been customized since the last update. All files will be replaced. Are you sure you want to continue? [Y/n] ${RESET}" REPLY
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
        echo -e "${GREEN}Keeping every customized file${RESET}"
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
    git clone --branch "$current_branch" https://github.com/end-4/dots-hyprland/ --depth=1 "$temp_folder"
    # Replace the existing dotfiles with the new ones
    for folder in "${folders[@]}"; do
        find "$temp_folder/$folder" -print0 | while IFS= read -r -d '' file; do
            file=${file//$temp_folder\//}
            if [[ -d "$temp_folder/$file" ]]; then
                mkdir -p "$(get_destination $file)"
            fi
            if [[ -f "$temp_folder/$file" ]] && ! file_in_excludes "$file" && [[ ! " ${modified_files[*]} " =~ " $file " ]]; then
                destination=$(get_destination $file)
                echo -e "${BLUE}Replacing $destination ...${RESET}"
                mkdir -p "$(dirname "$destination")"
                cp -f "$temp_folder/$file" "$destination"
            fi
        done
    done
    
    deleted_files=()
    renamed_files=()
    
    # Extract deleted files and save to variable
    deleted_files=$(git diff --name-status HEAD origin/$current_branch | awk '$1 == "D" {print $2}')
    
    # Extract renamed files and save to variable
    renamed_files=$(git diff --name-status HEAD origin/$current_branch | awk '$1 ~ /^R/ {print $2}')
    
    
    files_to_remove=()
    
    for file in $deleted_files; do
        
        if ! file_in_excludes "$file" && [[ ! " ${modified_files[*]} " =~ " $file " ]]; then
            files_to_remove+=("$file")
        fi
    done
    for file in $renamed_files; do
        if ! file_in_excludes "$file" && [[ ! " ${modified_files[*]} " =~ " $file " ]]; then
            files_to_remove+=("$file")
        fi
    done
    
    # Remove files
    for file in "${files_to_remove[@]}"; do
        echo -e "${YELLOW}Removing $file ...${RESET}"
	homefile="$(get_destination $file)"
        if [[ -f "$homefile" ]]; then
            rm -rf "$homefile"
        fi
    done
    
    echo -e "${GREEN}New dotfiles have been copied. Cleaning up temporary folder...${RESET}"
    rm -rf "$temp_folder"
    echo -e "${GREEN}Done. You may exit now.${RESET}"
    exit 0
fi


# Check git diff to determine which files have been removed and which have been renamed
deleted_files=()
renamed_files=()

# Extract deleted files and save to variable
deleted_files=$(git diff --name-status @{1} | awk '$1 == "D" {print $2}')

# Extract renamed files and save to variable
renamed_files=$(git diff --name-status @{1} | awk '$1 ~ /^R/ {print $2}')


files_to_remove=()

for file in $deleted_files; do
    
    if ! file_in_excludes "$file" && [[ ! " ${modified_files[*]} " =~ " $file " ]]; then
        files_to_remove+=("$file")
    fi
done
for file in $renamed_files; do
    if ! file_in_excludes "$file" && [[ ! " ${modified_files[*]} " =~ " $file " ]]; then
        files_to_remove+=("$file")
    fi
done

# Remove files
for file in "${files_to_remove[@]}"; do
    echo -e "${YELLOW}Removing $file ...${RESET}"
    homefile=$(get_destination $file)
    if [[ -f "$homefile" ]]; then
        rm -rf "$homefile"
    fi
done


# Replace unmodified files
for folder in "${folders[@]}"; do
    find "$folder" -print0 | while IFS= read -r -d '' file; do
        if [[ -d "$file" ]]; then
            mkdir -p "$(get_destination $file)"
        fi
        if [[ -f "$file" ]] && ! file_in_excludes "$file" && [[ ! " ${modified_files[*]} " =~ " $file " ]]; then
            destination="$(get_destination $file)"
            echo -e "${BLUE}Replacing \"$destination\" ...${RESET}"
            mkdir -p "$(dirname "$destination")"
            cp -f "$base/$file" "$destination"
        fi
    done
done

echo -e "${GREEN}Done. You may exit now.${RESET}"

