#!/bin/bash
# This script updates the dotfiles by fetching the latest version from the Git repository and then replacing files
# that have not been modified by the user to preserve changes. The remaining files will be replaced with the new ones.

cd "$(dirname "$0")"
export base="$(pwd)"

function get_checksum() {
  # Get the checksum of a specific file
  md5sum "$1" | awk '{print $1}'
}

# Define the folders to update
folders=(".config" ".local")
exclude_folders=("/home/janik/.config/hypr/custom")

# Build the exclude string for find command
exclude_string=""
for folder in "${exclude_folders[@]}"; do
    exclude_string+="! -path $folder -prune -o "
done

# Then check which files have been modified since the last update
modified_files=()

# Find all files in the specified folders and their subfolders, excluding specified folders
while IFS= read -r -d '' file; do
    # Calculate checksums
    base_checksum=$(get_checksum "$base/$file")
    home_checksum=$(get_checksum "$HOME/$file")
    # Compare checksums and add to modified_files if necessary
    if [[ $base_checksum != $home_checksum ]]; then
        modified_files+=("$file")
    fi
done < <(eval find "${folders[@]}" -type f $exclude_string -print0)

echo "Modified files: ${modified_files[@]}"

# Output all modified files
if [[ ${#modified_files[@]} -gt 0 ]]; then
    echo "The following files have been modified since the last update:"
    for file in "${modified_files[@]}"; do
        echo "$file"
    done
else
    echo "No files found that have been modified since the last installation/update. All files will be replaced. Are you sure you want to continue? [y/N] "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Ask if the user wants to keep them
read -p "Do you want to keep these files untouched? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Keeping modified files."
else
    echo "Replacing all files."
    modified_files=()
fi

# Then update the repository
git pull

# Now only replace the files that are not modified by the user
for folder in "${folders[@]}"; do
    # Find all files (including those in subdirectories) and copy them
    find "$folder" -type f $exclude_string -print0 | while IFS= read -r -d '' file; do
        if [[ -f "$file" && ! " ${modified_files[@]} " =~ " ${file} " ]]; then
            # Construct the destination path
            destination="$HOME/$file"
            # Copy the file
            cp -rf "$base/$file" "$destination"
        fi
    done
done

# Add the new files, because maybe the update added new files
for folder in "${folders[@]}"; do
    # Find all files (including those in subdirectories) and copy them
    find "$folder" -type f $exclude_string -print0 | while IFS= read -r -d '' file; do
        if [[ ! -f "$HOME/$file" ]]; then
            echo "Adding new file: $file"
            # Construct the destination path
            destination="$HOME/$file"
            # Copy the file
            cp -rf "$base/$file" "$destination"
        fi
    done
done
