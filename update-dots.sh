#!/bin/bash
# This script updates the dotfiles by fetching the latest version from the Git repository and then replacing files
# that have not been modified by the user to preserve changes. The remaining files will be replaced with the new ones.

set -e
cd "$(dirname "$0")"
export base="$(pwd)"


# Define paths to update
folders=(".config" ".local")
excludes=(".config/hypr/custom", ".config/ags/user_options.js", ".config/hypr/hyprland.conf")

function get_checksum() {
  # Get the checksum of a specific file
  md5sum "$1" | awk '{print $1}'
}

function file_in_excludes() {
  # Check if a file is in the exclude_folders
  for exc in "${excludes[@]}"; do
    if [[ $1 == $exc* ]]; then
      return 0
    fi
  done
  return 1
}

# Then check which files have been modified by the user since the last update to preserve user configurations
modified_files=()

# Find all files in the specified folders and their subfolders
while IFS= read -r -d '' file; do
    # If the file is not in the home directory, skip it
    if [[ ! -f "$HOME/$file" ]]; then
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


echo "Modified files: ${modified_files[@]}"
echo "Excluded files and folders: ${excludes[@]}"

# Output all modified files
if [[ ${#modified_files[@]} -gt 0 ]]; then
    echo "The following files have been modified since the last update:"
    for file in "${modified_files[@]}"; do
        echo "$file"
    done
else
    echo "No files found that have been modified since the last update. All files will be replaced. Are you sure you want to continue? [Y/n] "
    read -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "Exiting."
        exit 0
    fi
fi

echo "Do you want to keep these files untouched?"
echo "[Y] Yes, keep them."
echo "[n] No, replace them."
echo "[i] Check the files individually." 
# Ask if the user wants to keep them
read -p "Answer: " -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "Replacing all files."
    modified_files=()
elif [[ $REPLY =~ ^[Ii]$ ]]; then
    new_modified_files=()
    replaced_files=()
    for file in "${modified_files[@]}"; do
        echo "Do you want to keep $file untouched?"
        echo "[Y] Yes, keep it."
        echo "[n] No, replace it."
        read -p "Answer: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo "Keeping $file."
            new_modified_files+=("$file")
        else
            replaced_files+=("$file")
        fi
    done
    modified_files=("${new_modified_files[@]}")
    # verify the files that will be kept
    echo "_____________________________________________________"
    echo "These User configured/modifed files will be kept:"
    for file in "${modified_files[@]}"; do
        echo "$file"
    done
    echo "_____________________________________________________"
    echo "These User configured/modifed files will be replaced:"
    for file in "${replaced_files[@]}"; do
        echo "$file"
    done
    echo "_____________________________________________________"
    echo "Do you want to continue?"
    echo "[y] Yes, continue."
    echo "[N] No, exit."
    read -p "Answer: " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 0
    fi
else
    echo "Keeping every modified file"
fi

# Then update the repository
if git pull; then
    echo "Git pull successful."
else
    # If the pull failed, clone the repository to a temporary folder and copy the files from there
    echo "Git pull failed. Consider recloning the project or resolving conflicts manually."
    echo "Should I clone the repository to a temporary folder in cache and copy the files from there? [y/N] "
    read -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 1
    fi

    mkdir -p ./cache
    temp_folder=$(mktemp -d -p ./cache)
    git clone https://github.com/end-4/dots-hyprland/ "$temp_folder"
    # Replace the existing dotfiles with the new ones
    for folder in "${folders[@]}"; do
        # Find all files (including those in subdirectories) and copy them
        find "$temp_folder/$folder" -type f -print0 | while IFS= read -r -d '' file; do
            if [[ -f "$file" ]] && ! file_in_excludes "$file";  then
                # Construct the destination path
                destination="$HOME/$file"
                # Create the destination folder if it doesn't exist
                mkdir -p "$(dirname "$destination")"
                # Copy the file
                cp -f "$file" "$destination"
            fi
        done
    done
    echo "New dotfiles have been copied. Cleaning up temporary folder."
    rm -rf "$temp_folder"
fi


# Now only replace the files that are not modified by the user
for folder in "${folders[@]}"; do
    # Find all files (including those in subdirectories) and copy them
    find "$folder" -print0 | while IFS= read -r -d '' file; do
        # if the file is a directory, ensure it exists in the home directory
        if [[ -d "$file" ]]; then
            mkdir -p "$HOME/$file"
        fi
        # Check if the file is a regular file and not in the exclude_folders
        if [[ -f "$file" ]] && ! file_in_excludes "$file";  then
            if [[ ! " ${modified_files[@]} " =~ " ${file} " ]]; then
                # Construct the destination path
                destination="$HOME/$file"
                # Copy the file
                # Create the destination folder if it doesn't exist
                mkdir -p "$(dirname "$destination")"
                cp -f "$base/$file" "$destination"
            fi
        fi
    done
done

