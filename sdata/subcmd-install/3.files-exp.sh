# This script is meant to be sourced.
# It's not for directly running.

# TODO: https://github.com/end-4/dots-hyprland/issues/2137

# Configuration file
CONFIG_FILE="sdata/subcmd-install/3.files.yaml"

# =============================================================================
wizard_update_preferences() {
    echo -e "${STY_CYAN}=== Dotfiles Customization ===${STY_RESET}"
    
    # Get current preferences
    current_shell=$(yq '.user_preferences.shell // "fish"' "$CONFIG_FILE")
    current_terminal=$(yq '.user_preferences.terminal // "kitty"' "$CONFIG_FILE")
    current_keybindings=$(yq '.user_preferences.keybindings // "default"' "$CONFIG_FILE")
    
    echo "Current preferences:"
    echo "  Shell: $current_shell"
    echo "  Terminal: $current_terminal"
    echo "  Keybindings: $current_keybindings"
    echo
    
    # Shell selection
    echo "Which shell do you prefer?"
    echo "1) fish (default)"
    echo "2) zsh"
    read -p "Enter choice [1-2]: " shell_choice
    
    case "$shell_choice" in
        1|"") shell="fish" ;;
        2) shell="zsh" ;;
        *) echo "Invalid choice, using fish"; shell="fish" ;;
    esac
    
    # Terminal selection
    echo
    echo "Which terminal do you prefer?"
    echo "1) kitty (default)"
    echo "2) foot"
    read -p "Enter choice [1-2]: " terminal_choice
    
    case "$terminal_choice" in
        1|"") terminal="kitty" ;;
        2) terminal="foot" ;;
        *) echo "Invalid choice, using kitty"; terminal="kitty" ;;
    esac
    
    # Keybindings selection
    echo
    echo "Which keybinding style do you prefer?"
    echo "1) default (arrow keys)"
    echo "2) vim (H/J/K/L)"
    read -p "Enter choice [1-2]: " keybind_choice
    
    case "$keybind_choice" in
        1|"") keybindings="default" ;;
        2) keybindings="vim" ;;
        *) echo "Invalid choice, using default"; keybindings="default" ;;
    esac
    
    # Update YAML in-place
    yq -i ".user_preferences.shell = \"$shell\"" "$CONFIG_FILE"
    yq -i ".user_preferences.terminal = \"$terminal\"" "$CONFIG_FILE"
    yq -i ".user_preferences.keybindings = \"$keybindings\"" "$CONFIG_FILE"
    
    echo
    echo "Preferences updated!"
}

# Get user preference
get_pref() {
    yq -r ".user_preferences.$1" "$CONFIG_FILE"
}

# Check if pattern should be processed based on user preferences
should_process_pattern() {
    local pattern="$1"
    local condition=$(echo "$pattern" | yq '.condition // "true"')

    # If no condition or condition is "true", always process
    if [[ "$condition" == "true" ]]; then
      return 0
    fi
    
    # Extract the preference type and value from condition
    local type=$(echo "$condition" | yq '.type')
    local value=$(echo "$condition" | yq '.value')
    
    [[ "$(get_pref "$type")" == "$value" ]]
    
}

# Compare hashes of files/directories, return true if they are the same, false otherwise
files_are_same() {
    local path1="$1"
    local path2="$2"
    
    # Check if paths exist
    if [[ ! -e "$path1" || ! -e "$path2" ]]; then
        return 1
    fi
    
    # For directories, use find + md5sum to compare recursively
    # For files, use md5sum directly
    if [[ -d "$path1" && -d "$path2" ]]; then
        # Compare directory contents using find and md5sum
        local hash1=$(find "$path1" -type f -exec md5sum {} \; | sort -k 2 | md5sum | awk '{print $1}')
        local hash2=$(find "$path2" -type f -exec md5sum {} \; | sort -k 2 | md5sum | awk '{print $1}')
        [[ "$hash1" == "$hash2" ]]
    elif [[ -f "$path1" && -f "$path2" ]]; then
        # Compare file hashes
        local hash1=$(md5sum "$path1" | awk '{print $1}')
        local hash2=$(md5sum "$path2" | awk '{print $1}')
        [[ "$hash1" == "$hash2" ]]
    else
        # One is a file, one is a directory - different types
        return 1
    fi
}

# Find next backup number
get_next_backup_number() {
    local base_path="$1"
    local counter=1

    while [[ -e "${base_path}.old.${counter}" ]]; do
        ((counter++))
    done

    echo $counter
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Run user preference wizard
case $ask in
  false) sleep 0 ;;
  *) wizard_update_preferences ;;
esac

# Read patterns from YAML file
readarray patterns < <(yq -o=j -I=0 '.patterns[]' "$CONFIG_FILE")

# Process each pattern
for pattern in "${patterns[@]}"; do
    from=$(echo "$pattern" | yq '.from' - | envsubst)
    to=$(echo "$pattern" | yq '.to' - | envsubst)
    mode=$(echo "$pattern" | yq '.mode' - | envsubst)
    condition=$(echo "$pattern" | yq '.condition // "true"')
    
    # Handle fontconfig fontset override
    # If FONTSET_DIR_NAME is set and this is the fontconfig pattern, use the fontset instead
    if [[ "$from" == "dots/.config/fontconfig" ]] && [[ -n "${FONTSET_DIR_NAME:-}" ]]; then
        from="dots-extra/fontsets/${FONTSET_DIR_NAME}"
        echo "Using fontset \"${FONTSET_DIR_NAME}\" for fontconfig"
    fi
    
    # Check if pattern should be processed
    if ! should_process_pattern "$pattern"; then
        # Format condition message nicely
        if [[ "$condition" != "true" ]]; then
            cond_type=$(echo "$condition" | yq -r '.type // ""')
            cond_value=$(echo "$condition" | yq -r '.value // ""')
            if [[ -n "$cond_type" && -n "$cond_value" ]]; then
                echo "Skipping $from -> $to (condition not met: $cond_type == '$cond_value')"
            else
                echo "Skipping $from -> $to (condition not met)"
            fi
        else
            echo "Skipping $from -> $to (condition not met)"
        fi
        continue
    fi
    
    echo "Processing: $from -> $to (mode: $mode)"
    
    # Build exclude arguments for rsync
    excludes=()
    if echo "$pattern" | yq -e '.excludes' >/dev/null 2>&1; then
        while IFS= read -r exclude; do
            excludes+=(--exclude "$exclude")
        done < <(echo "$pattern" | yq -r '.excludes[]')
    fi
    
    # Check if source exists
    if [[ ! -e "$from" ]]; then
        echo "Warning: Source does not exist: $from (skipping)"
        continue
    fi
    
    # Ensure destination directory exists for files
    if [[ -f "$from" ]]; then
        v mkdir -p "$(dirname "$to")"
    fi
    
    # Execute based on mode
    case $mode in
        "sync")
            if [[ -d "$from" ]]; then
                warning_rsync_delete
                v rsync -av --delete "${excludes[@]}" "$from/" "$to/"
            else
                warning_rsync_normal
                # For files, don't use trailing slash and don't use --delete
                v rsync -av "${excludes[@]}" "$from" "$to"
            fi
            ;;
        "soft")
            warning_rsync_normal
            if [[ -d "$from" ]]; then
                v rsync -av "${excludes[@]}" "$from/" "$to/"
            else
                # For files, don't use trailing slash
                v rsync -av "${excludes[@]}" "$from" "$to"
            fi
            ;;
        "hard")
            v cp -r "$from" "$to"
            ;;
        "hard-backup")
            if [[ -e "$to" ]]; then
                if files_are_same "$from" "$to"; then
                    echo "Files are identical, skipping backup"
                else
                    backup_number=$(get_next_backup_number "$to")
                    v mv "$to" "$to.old.$backup_number"
                    v cp -r "$from" "$to"
                fi
            else
                v cp -r "$from" "$to"
            fi
            ;;
        "soft-backup")
            if [[ -e "$to" ]]; then
                if files_are_same "$from" "$to"; then
                    echo "Files are identical, skipping backup"
                else
                    v cp -r "$from" "$to.new"
                fi
            else
                v cp -r "$from" "$to"
            fi
            ;;
        "skip")
            echo "Skipping $from"
            ;;
        "skip-if-exists")
            if [[ -e "$to" ]]; then
                echo "Skipping $from (destination exists)"
            else
                v cp -r "$from" "$to"
            fi
            ;;
        *)
            echo "Unknown mode: $mode"
            ;;
    esac
done

#####################################################################################
