#!/bin/bash
# This script updates the dotfiles by fetching the latest version from the Git repository and then replacing files
# that have not been modified by the user to preserve changes. The remaining files will be replaced with the new ones.

cd "$(dirname "$0")"
export base="$(pwd)"


# Define the folders to update
folders=(".config" ".local")
exclude_folders=(".config/hypr/custom")

function get_checksum() {
  # Get the checksum of a specific file
  md5sum "$1" | awk '{print $1}'
}

function file_in_exclude_folders() {
  # Check if a file is in the exclude_folders
  for exclude_folder in "${exclude_folders[@]}"; do
    if [[ $1 == $exclude_folder* ]]; then
      return 0
    fi
  done
  return 1
}




# Then check which files have been modified since the last update
modified_files=()

# Find all files in the specified folders and their subfolders
while IFS= read -r -d '' file; do
    # Calculate checksums
    base_checksum=$(get_checksum "$base/$file")
    home_checksum=$(get_checksum "$HOME/$file")
    # Compare checksums and add to modified_files if necessary
    if [[ $base_checksum != $home_checksum ]]; then
        modified_files+=("$file")
    fi
done < <(find "${folders[@]}" -type f -print0)


echo "Modified files: ${modified_files[@]}"

# Output all modified files
if [[ ${#modified_files[@]} -gt 0 ]]; then
    echo "The following files have been modified since the last update:"
    for file in "${modified_files[@]}"; do
        echo "$file"
    done
else
    echo "No files found that have been modified since the last update. All files will be replaced. Are you sure you want to continue? [Y/n] "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo "Exiting."
        exit 0
    fi
fi

# Ask if the user wants to keep them
read -p "Do you want to keep these files untouched? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
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
    find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
        if [[ -f "$file" ]] && ! file_in_exclude_folders "$file";  then
            if [[ ! " ${modified_files[@]} " =~ " ${file} " ]]; then
                # Construct the destination path
                destination="$HOME/$file"
                # Copy the file
                cp -rf "$base/$file" "$destination"
            fi
        fi
    done
done

# Add the new files, because maybe the update added new files
for folder in "${folders[@]}"; do
    # Find all files (including those in subdirectories) and copy them
    find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
        if [[ ! -f "$HOME/$file" ]] && ! file_in_exclude_folders "$file"; then
            echo "Adding new file: $file"
            # Construct the destination path
            destination="$HOME/$file"
            # Copy the file
            cp -rf "$base/$file" "$destination"
        fi
    done
done


