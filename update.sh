#!/usr/bin/env bash
#
# update.sh - Enhanced dotfiles update script (Update-only, no installation)
#
# Features:
# - Pull latest commits from remote
# - Smart dependency installation (auto-enabled)
# - Only process files that differ between local and remote commits
# - Auto-sync mode for files
# - Numbered selection for files and packages
# - Handle config file conflicts with user choices
# - Respect .updateignore and .autosync files
# - Focus on updates only, no system setup
#
set -euo pipefail

# === Configuration ===
FORCE_CHECK=false
CHECK_PACKAGES=false
CHECK_DEPENDENCIES=true
AUTO_SYNC_MODE=false
REPO_DIR="$(cd "$(dirname "$0")" &>/dev/null && pwd)"
ARCH_PACKAGES_DIR="${REPO_DIR}/arch-packages"
UPDATE_IGNORE_FILE="${REPO_DIR}/.updateignore"
HOME_UPDATE_IGNORE_FILE="${HOME}/.updateignore"
AUTO_SYNC_FILE="${REPO_DIR}/.autosync"
HOME_AUTO_SYNC_FILE="${HOME}/.autosync"
DEPLISTFILE="${REPO_DIR}/scriptdata/dependencies.conf"

# Global variables to track pull state
PRE_PULL_HEAD=""
POST_PULL_HEAD=""
PULL_HAD_CHANGES=false

# Directories to monitor for changes
MONITOR_DIRS=(".config" ".local/bin")

# === Color Codes ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# === Helper Functions ===
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_header() {
    echo -e "\n${PURPLE}=== $1 ===${NC}"
}

die() {
    log_error "$1"
    exit 1
}

# Function to safely read input with terminal compatibility
safe_read() {
    local prompt="$1"
    local varname="$2"
    local default="${3:-}"

    echo -n "$prompt"
    if [[ -t 0 ]]; then
        read -r input_value
    else
        input_value="$default"
        echo "$default"
        log_warning "Non-interactive mode, using default: $default"
    fi
    
    if [[ -z "$input_value" && -n "$default" ]]; then
        input_value="$default"
    fi
    
    eval "$varname='$input_value'"
    return 0
}

# Function to get files that differ between local and remote commits
get_diff_files_between_commits() {
    local local_commit="${1:-HEAD}"
    local remote_commit="${2:-origin/$(git branch --show-current)}"
    
    # If we have tracked pull information, use that
    if [[ -n "$PRE_PULL_HEAD" && -n "$POST_PULL_HEAD" && "$PRE_PULL_HEAD" != "$POST_PULL_HEAD" ]]; then
        git diff --name-only "$PRE_PULL_HEAD" "$POST_PULL_HEAD" 2>/dev/null || {
            log_warning "Could not compare pre/post pull commits, falling back to alternative methods" >&2
            return 1
        }
        return 0
    fi
    
    # Get files that are different between the two commits
    git diff --name-only "$local_commit" "$remote_commit" 2>/dev/null || {
        log_warning "Could not compare commits, falling back to all files" >&2
        return 1
    }
}

# Function to check if a file should be ignored
should_ignore() {
    local file_path="$1"
    local relative_path="${file_path#$HOME/}"
    local repo_relative=""
    if [[ "$file_path" == "$REPO_DIR"* ]]; then
        repo_relative="${file_path#$REPO_DIR/}"
    fi

    for ignore_file in "$UPDATE_IGNORE_FILE" "$HOME_UPDATE_IGNORE_FILE"; do
        [[ -f "$ignore_file" ]] || continue
        
        while IFS= read -r pattern || [[ -n "$pattern" ]]; do
            [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
            pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [[ -z "$pattern" ]] && continue

            # Direct match
            if [[ "$relative_path" == "$pattern" || "$repo_relative" == "$pattern" ]]; then
                return 0
            fi
            
            # Directory pattern
            if [[ "$pattern" == */ ]]; then
                local dir_pattern="${pattern%/}"
                if [[ "$relative_path" == "$dir_pattern"/* || "$repo_relative" == "$dir_pattern"/* ]]; then
                    return 0
                fi
            fi
            
            # Root pattern
            if [[ "$pattern" == /* ]]; then
                local root_pattern="${pattern#/}"
                if [[ "$relative_path" == "$root_pattern" || "$relative_path" == "$root_pattern"/* ]] ||
                   [[ "$repo_relative" == "$root_pattern" || "$repo_relative" == "$root_pattern"/* ]]; then
                    return 0
                fi
            fi
            
            # Glob pattern
            if [[ "$pattern" == *"*"* ]]; then
                if [[ "$relative_path" == $pattern || "$repo_relative" == $pattern ]]; then
                    return 0
                fi
            fi
            
            # Substring match as fallback
            if [[ "$file_path" == *"$pattern"* || "$relative_path" == *"$pattern"* ]]; then
                return 0
            fi
        done < "$ignore_file"
    done
    return 1
}

# Function to check if a file should be auto-synced
should_auto_sync() {
    local file_path="$1"
    local relative_path="${file_path#$HOME/}"
    local repo_relative=""
    if [[ "$file_path" == "$REPO_DIR"* ]]; then
        repo_relative="${file_path#$REPO_DIR/}"
    fi

    for autosync_file in "$AUTO_SYNC_FILE" "$HOME_AUTO_SYNC_FILE"; do
        [[ -f "$autosync_file" ]] || continue
        
        while IFS= read -r pattern || [[ -n "$pattern" ]]; do
            [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
            pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [[ -z "$pattern" ]] && continue

            # Direct match
            if [[ "$relative_path" == "$pattern" || "$repo_relative" == "$pattern" ]]; then
                return 0
            fi
            
            # Directory pattern  
            if [[ "$pattern" == */ ]]; then
                local dir_pattern="${pattern%/}"
                if [[ "$relative_path" == "$dir_pattern"/* || "$repo_relative" == "$dir_pattern"/* ]]; then
                    return 0
                fi
            fi
            
            # Root pattern
            if [[ "$pattern" == /* ]]; then
                local root_pattern="${pattern#/}"
                if [[ "$relative_path" == "$root_pattern" || "$relative_path" == "$root_pattern"/* ]] ||
                   [[ "$repo_relative" == "$root_pattern" || "$repo_relative" == "$root_pattern"/* ]]; then
                    return 0
                fi
            fi
            
            # Glob pattern
            if [[ "$pattern" == *"*"* ]]; then
                if [[ "$relative_path" == $pattern || "$repo_relative" == $pattern ]]; then
                    return 0
                fi
            fi
            
            # Substring match as fallback
            if [[ "$file_path" == *"$pattern"* || "$relative_path" == *"$pattern"* ]]; then
                return 0
            fi
        done < "$autosync_file"
    done
    return 1
}

# Function to show file diff with syntax highlighting if possible
show_diff() {
    local file1="$1"
    local file2="$2"

    echo -e "\n${CYAN}Showing differences:${NC}"
    echo -e "${CYAN}Current file: $file1${NC}"
    echo -e "${CYAN}Updated file: $file2${NC}"
    echo "----------------------------------------"

    if command -v diff &>/dev/null; then
        diff -u "$file1" "$file2" || true
    else
        echo "diff command not available"
    fi
    echo "----------------------------------------"
}

# Function to handle file conflicts with numbered options
handle_file_conflict() {
    local repo_file="$1"
    local home_file="$2"
    local filename=$(basename "$home_file")
    local dirname=$(dirname "$home_file")

    # Check if file should be auto-synced
    if should_auto_sync "$home_file"; then
        cp -p "$repo_file" "$home_file"
        log_success "Auto-synced: $home_file"
        return
    fi

    echo -e "\n${YELLOW}Conflict detected:${NC} $home_file"
    echo "Repository version differs from your local version."
    echo
    echo "Choose an action:"
    echo "1) Update with repository version (replace local)"
    echo "2) Keep current local version unchanged"
    echo "3) Backup current as ${filename}.old, use repository version"
    echo "4) Save repository version as ${filename}.new, keep current"
    echo "5) Show diff and decide"
    echo "6) Skip this file"
    echo "7) Add to ignore and skip"
    echo "8) Add to auto-sync and update"
    echo

    while true; do
        if ! safe_read "Enter your choice (1-8): " choice "6"; then
            echo
            log_warning "Failed to read input. Skipping file."
            return
        fi

        case $choice in
        1)
            cp -p "$repo_file" "$home_file"
            log_success "Updated $home_file with repository version"
            break
            ;;
        2)
            log_info "Keeping current version of $home_file"
            break
            ;;
        3)
            mv "$home_file" "${dirname}/${filename}.old"
            cp -p "$repo_file" "$home_file"
            log_success "Backed up current to ${filename}.old and updated with repository version"
            break
            ;;
        4)
            cp -p "$repo_file" "${dirname}/${filename}.new"
            log_success "Saved repository version as ${filename}.new, kept current file"
            break
            ;;
        5)
            show_diff "$home_file" "$repo_file"
            echo
            echo "After reviewing the diff, choose:"
            echo "r) Update with repository version"
            echo "k) Keep current version"
            echo "b) Backup current and use repository version"
            echo "n) Save repository version as .new"
            echo "s) Skip this file"
            echo "i) Add to ignore and skip"
            echo "a) Add to auto-sync and update"

            if ! safe_read "Enter your choice (r/k/b/n/s/i/a): " subchoice "s"; then
                echo
                log_warning "Failed to read input. Skipping file."
                return
            fi

            case $subchoice in
            r) 
                cp -p "$repo_file" "$home_file"
                log_success "Updated $home_file with repository version"
                break
                ;; 
            k) 
                log_info "Keeping current version of $home_file"
                break
                ;; 
            b) 
                mv "$home_file" "${dirname}/${filename}.old"
                cp -p "$repo_file" "$home_file"
                log_success "Backed up current file and updated"
                break
                ;; 
            n) 
                cp -p "$repo_file" "${dirname}/${filename}.new"
                log_success "Saved repository version as ${filename}.new"
                break
                ;; 
            s) 
                log_info "Skipping $home_file"
                break
                ;; 
            i) 
                local relative_path_to_home="${home_file#$HOME/}"
                echo "$relative_path_to_home" >> "$HOME_UPDATE_IGNORE_FILE"
                log_success "Added '$relative_path_to_home' to ignore list and skipped."
                break
                ;; 
            a) 
                local relative_path_to_home="${home_file#$HOME/}"
                echo "$relative_path_to_home" >> "$HOME_AUTO_SYNC_FILE"
                cp -p "$repo_file" "$home_file"
                log_success "Added '$relative_path_to_home' to auto-sync list and updated."
                break
                ;; 
            *)
                echo "Invalid choice. Please try again."
                ;; 
            esac
            ;;
        6) 
            log_info "Skipping $home_file"
            break
            ;;
        7) 
            local relative_path_to_home="${home_file#$HOME/}"
            echo "$relative_path_to_home" >> "$HOME_UPDATE_IGNORE_FILE"
            log_success "Added '$relative_path_to_home' to ignore list and skipped."
            break
            ;;
        8) 
            local relative_path_to_home="${home_file#$HOME/}"
            echo "$relative_path_to_home" >> "$HOME_AUTO_SYNC_FILE"
            cp -p "$repo_file" "$home_file"
            log_success "Added '$relative_path_to_home' to auto-sync list and updated."
            break
            ;;
        *)
            echo "Invalid choice. Please enter 1-8."
            ;;
        esac
    done
}

# Function to update Python packages using uv (only if already installed)
update_python_packages() {
    if ! command -v uv >/dev/null 2>&1; then
        log_warning "uv not found. Skipping Python package updates."
        log_info "If you need uv, please run install.sh first."
        return 1
    fi

    local python_pkgs_file="${REPO_DIR}/scriptdata/python-packages"
    
    if [[ ! -f "$python_pkgs_file" ]]; then
        log_warning "Python packages file not found: $python_pkgs_file"
        return 1
    fi

    log_info "Updating Python packages using uv..."
    
    if [[ -f "${REPO_DIR}/scriptdata/installers" ]]; then
        source "${REPO_DIR}/scriptdata/environment-variables" 2>/dev/null || true
        source "${REPO_DIR}/scriptdata/installers"
        install-python-packages
        log_success "Python packages updated successfully"
    else
        log_error "Could not find installers script"
        return 1
    fi
}

# Function to handle dependencies with smart installation (auto-enabled)
handle_dependencies() {
    if [[ ! -f "$DEPLISTFILE" ]]; then
        log_warning "Dependencies file not found: $DEPLISTFILE"
        return 1
    fi

    # Check if yay is available
    if ! command -v yay >/dev/null 2>&1; then
        log_warning "yay not found. Cannot manage dependencies."
        log_info "Please run install.sh first to set up the package manager."
        return 1
    fi

    # Source required files
    if [[ -f "${REPO_DIR}/scriptdata/environment-variables" ]]; then
        source "${REPO_DIR}/scriptdata/environment-variables"
    fi
    if [[ -f "${REPO_DIR}/scriptdata/functions" ]]; then
        source "${REPO_DIR}/scriptdata/functions"
    fi

    # Remove comments and empty lines from dependencies file
    local -a pkglist=()
    if [[ -f "${REPO_DIR}/scriptdata/functions" ]]; then
        mkdir -p "${REPO_DIR}/cache"
        remove_bashcomments_emptylines "${DEPLISTFILE}" "${REPO_DIR}/cache/dependencies_stripped.conf"
        readarray -t pkglist < "${REPO_DIR}/cache/dependencies_stripped.conf"
    else
        # Fallback method
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [[ -n "$line" ]] && pkglist+=("$line")
        done < "$DEPLISTFILE"
    fi

    if [[ ${#pkglist[@]} -eq 0 ]]; then
        log_info "No dependencies found to update"
        return 0
    fi

    # Smart dependency handling: separate installed vs new packages
    local installed_packages=()
    local new_packages=()
    
    for pkg in "${pkglist[@]}"; do
        if pacman -Qq "$pkg" &>/dev/null; then
            installed_packages+=("$pkg")
        else
            new_packages+=("$pkg")
        fi
    done

    log_info "Smart dependency analysis:"
    log_info "- Total dependencies in config: ${#pkglist[@]}"
    log_info "- Currently installed: ${#installed_packages[@]}"
    log_info "- New/missing packages: ${#new_packages[@]}"

    # Always update installed packages
    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        log_info "Updating ${#installed_packages[@]} installed dependencies..."
        if yay -S --needed --noconfirm "${installed_packages[@]}"; then
            log_success "Installed dependencies updated successfully"
        else
            log_warning "Some installed dependencies failed to update"
        fi
    fi

    # Auto-install new dependencies if they exist
    if [[ ${#new_packages[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}Found ${#new_packages[@]} new dependencies:${NC}"
        printf " - %s\n" "${new_packages[@]}"
        
        if safe_read "Install these new dependencies automatically? (Y/n): " install_new "Y"; then
            if [[ ! "$install_new" =~ ^[Nn]$ ]]; then
                log_info "Installing ${#new_packages[@]} new dependencies..."
                if yay -S --needed --noconfirm "${new_packages[@]}"; then
                    log_success "New dependencies installed successfully"
                else
                    log_warning "Some new dependencies failed to install"
                fi
            else
                log_info "Skipping installation of new dependencies"
            fi
        fi
    fi

    return 0
}

# Function to check if PKGBUILD has changed between commits
check_pkgbuild_changed() {
    local pkg_dir="$1"
    local pkgbuild_path="${pkg_dir}/PKGBUILD"

    [[ ! -f "$pkgbuild_path" ]] && return 1

    local relative_path="${pkgbuild_path#$REPO_DIR/}"
    local current_branch=$(git branch --show-current)
    local remote_branch="origin/${current_branch}"

    if [[ "$FORCE_CHECK" == true ]]; then
        return 0
    fi

    # Check if PKGBUILD changed between local and remote
    if git show-ref --verify --quiet "refs/remotes/$remote_branch"; then
        if git diff --name-only "HEAD" "$remote_branch" 2>/dev/null | grep -q "^${relative_path}$"; then
            return 0
        fi
    fi

    return 1
}

# Function to list available packages with numbered selection
list_and_select_packages() {
    local available_packages=()
    local changed_packages=()

    if [[ ! -d "$ARCH_PACKAGES_DIR" ]]; then
        log_warning "No arch-packages directory found"
        return 1
    fi

    for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
        if [[ -f "${pkg_dir}/PKGBUILD" ]]; then
            local pkg_name=$(basename "$pkg_dir")
            available_packages+=("$pkg_name")

            if check_pkgbuild_changed "$pkg_dir"; then
                changed_packages+=("$pkg_name")
            fi
        fi
    done

    if [[ ${#available_packages[@]} -eq 0 ]]; then
        log_info "No packages found in arch-packages directory"
        return 1
    fi

    echo -e "\n${CYAN}Available packages:${NC}"
    for i in "${!available_packages[@]}"; do
        local pkg="${available_packages[$i]}"
        # Check if package is installed
        local installed_status=""
        if pacman -Qq "$pkg" &>/dev/null; then
            installed_status="${GREEN}✓${NC}"
        else
            installed_status="${RED}✗${NC}"
        fi
        
        if [[ " ${changed_packages[*]} " =~ " ${pkg} " ]]; then
            printf "%2d) %s ${GREEN}● %s${NC} (PKGBUILD changed)\n" $((i+1)) "$installed_status" "$pkg"
        else
            printf "%2d) %s ○ %s\n" $((i+1)) "$installed_status" "$pkg"
        fi
    done

    if [[ ${#changed_packages[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}Packages with changed PKGBUILDs: ${changed_packages[*]}${NC}"
    fi

    echo -e "\n${CYAN}Legend:${NC} ${GREEN}✓${NC} = installed, ${RED}✗${NC} = not installed, ${GREEN}●${NC} = PKGBUILD changed"

    echo
    echo "Package update options:"
    echo "1) Rebuild packages with changed PKGBUILDs (installed only)"
    echo "2) Rebuild all installed packages"
    echo "3) Select specific packages by number"
    echo "4) Skip package updates"

    if ! safe_read "Choose an option (1-4): " pkg_choice "4"; then
        log_warning "Failed to read input. Skipping package updates."
        return 1
    fi

    local packages_to_build=()

    case $pkg_choice in
    1) 
        # Only rebuild changed packages that are installed
        for pkg in "${changed_packages[@]}"; do
            if pacman -Qq "$pkg" &>/dev/null; then
                packages_to_build+=("$pkg")
            fi
        done
        ;; 
    2) 
        # Only rebuild packages that are installed
        for pkg in "${available_packages[@]}"; do
            if pacman -Qq "$pkg" &>/dev/null; then
                packages_to_build+=("$pkg")
            fi
        done
        ;; 
    3) 
        echo
        echo "Enter the numbers of packages to rebuild (space-separated, e.g., 1 3 5-7 10):"
        if ! safe_read "Package numbers: " selections ""; then
            log_warning "Failed to read input. Skipping package updates."
            return 1
        fi

        if [[ -z "$selections" ]]; then
            log_info "No packages selected"
            return 0
        fi

        # Parse selections (support ranges like 5-7)
        for selection in $selections; do
            if [[ "$selection" == *-* ]]; then
                # Handle range
                IFS='-' read -r start end <<< "$selection"
                for ((i=start; i<=end; i++)); do
                    if [[ $i -ge 1 && $i -le ${#available_packages[@]} ]]; then
                        packages_to_build+=("${available_packages[$((i-1))]}")
                    fi
                done
            else
                # Handle single number
                if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 && $selection -le ${#available_packages[@]} ]]; then
                    packages_to_build+=("${available_packages[$((selection-1))]}")
                fi
            fi
        done
        ;; 
    4 | *) 
        log_info "Skipping package updates"
        return 0
        ;; 
    esac

    if [[ ${#packages_to_build[@]} -eq 0 ]]; then
        if [[ $pkg_choice -eq 1 && ${#changed_packages[@]} -eq 0 ]]; then
            log_info "No packages with changed PKGBUILDs found"
        else
            log_info "No packages selected for rebuilding"
        fi
        return 0
    fi

    echo -e "\n${CYAN}Packages to rebuild: ${packages_to_build[*]}${NC}"

    if ! safe_read "Proceed with rebuilding these packages? (Y/n): " confirm "Y"; then
        log_warning "Failed to read input. Skipping package rebuilding."
        return 1
    fi

    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        log_info "Package rebuilding cancelled by user"
        return 0
    fi

    local rebuilt_packages=0
    for pkg_name in "${packages_to_build[@]}"; do
        local pkg_dir="${ARCH_PACKAGES_DIR}/${pkg_name}"

        if [[ ! -d "$pkg_dir" || ! -f "${pkg_dir}/PKGBUILD" ]]; then
            log_error "Package not found or missing PKGBUILD: $pkg_name"
            continue
        fi

        log_info "Rebuilding package: $pkg_name"
        cd "$pkg_dir" || continue

        # Source PKGBUILD to get dependencies
        source ./PKGBUILD
        if [[ -n "${depends[*]:-}" ]]; then
            log_info "Updating dependencies for $pkg_name..."
            yay -S --needed --asdeps "${depends[@]}" || log_warning "Failed to update some dependencies for $pkg_name"
        fi

        if makepkg -si --noconfirm; then
            log_success "Successfully rebuilt and updated $pkg_name"
            ((rebuilt_packages++))
        else
            log_error "Failed to rebuild package $pkg_name"
        fi

        cd "$REPO_DIR" || die "Failed to return to repository directory"
    done

    if [[ $rebuilt_packages -eq 0 ]]; then
        log_warning "No packages were successfully rebuilt"
    else
        log_success "Successfully rebuilt $rebuilt_packages package(s)"
    fi

    return 0
}

# Function to check if we have differences between local and remote commits
has_commit_differences() {
    # If we tracked a pull operation with changes, return true
    if [[ "$PULL_HAD_CHANGES" == true ]]; then
        return 0
    fi
    
    local current_branch=$(git branch --show-current)
    local remote_branch="origin/${current_branch}"
    
    # Check if remote branch exists and differs from local
    if git show-ref --verify --quiet "refs/remotes/$remote_branch"; then
        if [[ "$(git rev-parse HEAD)" != "$(git rev-parse "$remote_branch" 2>/dev/null || echo "")" ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Function to sync configuration files
sync_config_files() {
    local -i files_processed=0 files_updated=0 files_created=0 files_skipped=0
    local -a commit_diff_files=()

    # Get changed files if not in force mode
    if [[ "$FORCE_CHECK" != true ]]; then
        if [[ "$PULL_HAD_CHANGES" == true && -n "$PRE_PULL_HEAD" && -n "$POST_PULL_HEAD" ]]; then
            # Use tracked pull information for most accurate diff
            while IFS= read -r file; do
                if [[ -n "$file" ]]; then
                    commit_diff_files+=("$file")
                fi
            done < <(git diff --name-only "$PRE_PULL_HEAD" "$POST_PULL_HEAD" 2>/dev/null || true)
            log_info "Using tracked pull changes (${PRE_PULL_HEAD:0:7} -> ${POST_PULL_HEAD:0:7})"
        else
            # Fallback to comparing with remote
            local current_branch=$(git branch --show-current)
            local remote_branch="origin/${current_branch}"
            
            if git show-ref --verify --quiet "refs/remotes/${remote_branch}"; then
                while IFS= read -r file; do
                    if [[ -n "$file" ]]; then
                        commit_diff_files+=("$file")
                    fi
                done < <(get_diff_files_between_commits "HEAD" "${remote_branch}")
            fi
        fi
        
        log_info "Found ${#commit_diff_files[@]} files with differences"
        if [[ ${#commit_diff_files[@]} -gt 0 ]]; then
            echo -e "${CYAN}Files to be processed:${NC}"
            printf " - %s\n" "${commit_diff_files[@]}"
        fi
    fi

    # Set up environment variables if available
    if [[ -f "${REPO_DIR}/scriptdata/environment-variables" ]]; then
        source "${REPO_DIR}/scriptdata/environment-variables"
    fi
    
    # Set default XDG directories if not set
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

    # Helper function to check if file should be processed
    should_process_file() {
        local file_path="$1"
        
        if [[ "$FORCE_CHECK" == true ]]; then
            return 0
        fi
        
        # Check if file is in the diff list
        local file_relative="${file_path#$REPO_DIR/}"
        for diff_file in "${commit_diff_files[@]}"; do
            if [[ "$diff_file" == "$file_relative" ]] || [[ "$file_relative" == "$diff_file" ]]; then
                return 0
            fi
            # Check if it's a directory match
            if [[ "$file_relative" == "$diff_file"/* ]] || [[ "$diff_file" == "$file_relative"/* ]]; then
                return 0
            fi
        done
        
        return 1
    }

    # Helper function to sync a file
    sync_file() {
        local src_file="$1"
        local dest_file="$2"
        
        should_ignore "$dest_file" && return 0
        
        mkdir -p "$(dirname "$dest_file")"
        
        if [[ -f "$dest_file" ]]; then
            if ! cmp -s "$src_file" "$dest_file"; then
                if should_auto_sync "$dest_file"; then
                    cp -p "$src_file" "$dest_file"
                    log_success "Auto-synced: $dest_file"
                    ((files_updated++))
                else
                    handle_file_conflict "$src_file" "$dest_file"
                    ((files_updated++))
                fi
            fi
        else
            cp -p "$src_file" "$dest_file"
            log_success "Created new file: $dest_file"
            ((files_created++))
        fi
        ((files_processed++))
    }

    # Helper function to sync directory recursively
    sync_directory() {
        local src_dir="$1"
        local dest_dir="$2"
        local process_all="${3:-false}"
        
        [[ ! -d "$src_dir" ]] && return 0
        
        mkdir -p "$dest_dir"
        
        find "$src_dir" -type f | while read -r src_file; do
            local rel_path="${src_file#$src_dir/}"
            local dest_file="$dest_dir/$rel_path"
            
            if [[ "$process_all" == true ]] || should_process_file "$src_file"; then
                sync_file "$src_file" "$dest_file"
            fi
        done
    }

    # Process .config directories (excluding fish and hypr for special handling)
    log_info "Processing miscellaneous configuration files..."
    if [[ -d ".config" ]]; then
        for config_item in .config/*/; do
            [[ ! -d "$config_item" ]] && continue
            
            local config_name=$(basename "$config_item")
            
            # Skip fish and hypr - handle them specially
            [[ "$config_name" == "fish" || "$config_name" == "hypr" ]] && continue
            
            local dest_config="$XDG_CONFIG_HOME/$config_name"
            
            # Check if any file in this config directory changed
            local has_changes=false
            if [[ "$FORCE_CHECK" == true ]]; then
                has_changes=true
            else
                for diff_file in "${commit_diff_files[@]}"; do
                    if [[ "$diff_file" == ".config/$config_name"* ]]; then
                        has_changes=true
                        break
                    fi
                done
            fi
            
            if [[ "$has_changes" == true ]]; then
                log_info "Processing config directory: $config_name"
                sync_directory "$config_item" "$dest_config" "$FORCE_CHECK"
            else
                log_info "Skipping unchanged config: $config_name"
                ((files_skipped++))
            fi
        done
        
        # Handle single config files in .config root
        find .config -maxdepth 1 -type f | while read -r config_file; do
            local config_name=$(basename "$config_file")
            local dest_file="$XDG_CONFIG_HOME/$config_name"
            
            if should_process_file "$config_file"; then
                sync_file "$config_file" "$dest_file"
            else
                ((files_skipped++))
            fi
        done
    fi

    # Handle Fish configuration with special logic
    log_info "Processing Fish configuration..."
    if [[ -d ".config/fish" ]]; then
        local fish_dest="$XDG_CONFIG_HOME/fish"
        
        # Check if fish config changed
        local fish_changed=false
        if [[ "$FORCE_CHECK" == true ]]; then
            fish_changed=true
        else
            for diff_file in "${commit_diff_files[@]}"; do
                if [[ "$diff_file" == ".config/fish"* ]]; then
                    fish_changed=true
                    break
                fi
            done
        fi
        
        if [[ "$fish_changed" == true ]]; then
            sync_directory ".config/fish" "$fish_dest" "$FORCE_CHECK"
        else
            log_info "Skipping unchanged Fish configuration"
        fi
    fi

    # Handle Hyprland configuration with special logic
    log_info "Processing Hyprland configuration..."
    if [[ -d ".config/hypr" ]]; then
        local hypr_dest="$XDG_CONFIG_HOME/hypr"
        mkdir -p "$hypr_dest"
        
        # Check if hypr config changed
        local hypr_changed=false
        if [[ "$FORCE_CHECK" == true ]]; then
            hypr_changed=true
        else
            for diff_file in "${commit_diff_files[@]}"; do
                if [[ "$diff_file" == ".config/hypr"* ]]; then
                    hypr_changed=true
                    break
                fi
            done
        fi
        
        if [[ "$hypr_changed" == true ]]; then
            # Handle regular hypr files (excluding special ones)
            find ".config/hypr" -type f | while read -r hypr_file; do
                local rel_path="${hypr_file#.config/hypr/}"
                local dest_file="$hypr_dest/$rel_path"
                
                # Skip custom directory and special config files
                if [[ "$rel_path" == custom/* ]]; then
                    continue
                fi
                
                # Handle special config files with extra care
                if [[ "$rel_path" == "hyprland.conf" || "$rel_path" == "hypridle.conf" || "$rel_path" == "hyprlock.conf" ]]; then
                    if should_process_file "$hypr_file"; then
                        echo -e "\n${YELLOW}Processing critical Hyprland config: $rel_path${NC}"
                        sync_file "$hypr_file" "$dest_file"
                    fi
                else
                    # Regular hypr files
                    if should_process_file "$hypr_file"; then
                        sync_file "$hypr_file" "$dest_file"
                    fi
                fi
            done
            
            # Handle custom directory (create if missing, but don't overwrite)
            if [[ -d ".config/hypr/custom" && ! -d "$hypr_dest/custom" ]]; then
                cp -r ".config/hypr/custom" "$hypr_dest/"
                log_success "Created Hyprland custom directory"
                ((files_created++))
            elif [[ -d "$hypr_dest/custom" ]]; then
                log_info "Preserving existing Hyprland custom directory"
            fi
        else
            log_info "Skipping unchanged Hyprland configuration"
        fi
    fi

    # Process other monitored directories
    for dir_name in "${MONITOR_DIRS[@]}"; do
        [[ "$dir_name" == ".config" ]] && continue  # Already handled above
        
        local src_dir="$REPO_DIR/$dir_name"
        local dest_dir="$HOME/$dir_name"
        
        if [[ -d "$src_dir" ]]; then
            # Check if directory has changes
            local dir_changed=false
            if [[ "$FORCE_CHECK" == true ]]; then
                dir_changed=true
            else
                for diff_file in "${commit_diff_files[@]}"; do
                    if [[ "$diff_file" == "$dir_name"* ]]; then
                        dir_changed=true
                        break
                    fi
                done
            fi
            
            if [[ "$dir_changed" == true ]]; then
                log_info "Processing directory: $dir_name"
                sync_directory "$src_dir" "$dest_dir" "$FORCE_CHECK"
            else
                log_info "Skipping unchanged directory: $dir_name"
            fi
        fi
    done

    # Handle .local/share directories
    for share_dir in ".local/share/icons" ".local/share/konsole"; do
        if [[ -d "$share_dir" ]]; then
            local dest_dir="$XDG_DATA_HOME/${share_dir#.local/share/}"
            
            # Check if share directory changed
            local share_changed=false
            if [[ "$FORCE_CHECK" == true ]]; then
                share_changed=true
            else
                for diff_file in "${commit_diff_files[@]}"; do
                    if [[ "$diff_file" == "$share_dir"* ]]; then
                        share_changed=true
                        break
                    fi
                done
            fi
            
            if [[ "$share_changed" == true ]]; then
                log_info "Processing share directory: $share_dir"
                mkdir -p "$dest_dir"
                
                if command -v rsync >/dev/null 2>&1; then
                    rsync -av --update "$share_dir/" "$dest_dir/" && \
                        log_success "Updated $(basename "$share_dir")" || \
                        log_warning "Failed to update $(basename "$share_dir")"
                else
                    cp -r "$share_dir/." "$dest_dir/" && \
                        log_success "Updated $(basename "$share_dir")" || \
                        log_warning "Failed to update $(basename "$share_dir")"
                fi
            else
                log_info "Skipping unchanged share directory: $(basename "$share_dir")"
            fi
        fi
    done

    # Return stats
    echo "$files_processed $files_updated $files_created $files_skipped"
}

# Main script starts here
main() {
    log_header "Enhanced Dotfiles Update Script (Smart Dependencies + Commit Diff)"

    local check=true

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        -f | --force) 
            FORCE_CHECK=true
            log_info "Force check mode enabled - will check all files regardless of git changes"
            shift
            ;; 
        -p | --packages) 
            CHECK_PACKAGES=true
            log_info "Package checking enabled"
            shift
            ;; 
        --no-deps) 
            CHECK_DEPENDENCIES=false
            log_info "Smart dependency management disabled"
            shift
            ;; 
        -a | --auto-sync) 
            AUTO_SYNC_MODE=true
            log_info "Auto-sync mode enabled for configured files"
            shift
            ;; 
        -h | --help) 
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --force         Force check all files even if no commit differences"
            echo "  -p, --packages      Enable package checking and rebuilding"
            echo "  --no-deps           Disable smart dependency management (enabled by default)"
            echo "  -a, --auto-sync     Enable auto-sync mode for configured files"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "This script updates your existing dotfiles by:"
            echo "  1. Pulling latest changes from git remote"
            echo "  2. Smart dependency management (auto-enabled) - updates installed, installs new"
            echo "  3. Optionally rebuilding packages with changed PKGBUILDs (if -p flag is used)"
            echo "  4. Syncing only files that differ between local and remote commits"
            echo "  5. Handling config file conflicts with resolution options"
            echo "  6. Reloading Hyprland if running"
            echo ""
            echo "Key Features:"
            echo "  - Smart Dependencies: Automatically updates installed packages and offers to install new ones"
            echo "  - Commit-based File Checking: Only processes files that differ between local and remote"
            echo "  - Conflict Resolution: Interactive handling of file differences"
            echo ""
            echo "Note: This script only updates existing installations."
            echo "      For initial setup, use install.sh instead."
            echo ""
            echo "Configuration files:"
            echo "  ~/.updateignore or .updateignore - files to ignore during updates"
            echo "  ~/.autosync or .autosync - files to auto-sync without prompting"
            exit 0
            ;; 
        --skip-notice) 
            log_warning "Skipping notice about update-only mode"
            check=false
            shift
            ;; 
        *) 
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;; 
        esac
    done

    if [[ "$check" == true ]]; then
        log_warning "THIS SCRIPT IS NOT FULLY TESTED AND MAY CAUSE ISSUES!"
        log_warning "It might be safer if you want to preserve your modifications and not delete added files,"
        log_warning "  but this can cause partial updates and therefore unexpected behavior like in #1856."
        log_warning "In general, prefer install.sh for updates."
        safe_read "Continue? (y/N): " response "N"

        if [[ "$response" =~ ^[Nn]$ ]]; then
            log_error "Update aborted by user"
            exit 1
        fi
    fi

    # Check if we're in a git repository
    cd "$REPO_DIR" || die "Failed to change to repository directory"

    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        die "Not in a git repository. Please run this script from your dotfiles repository."
    fi

    log_info "Running in git repository: $(git rev-parse --show-toplevel)"

    # Step 1: Pull latest commits
    log_header "Pulling Latest Changes"

    local current_branch=$(git branch --show-current)
    if [[ -z "$current_branch" ]]; then
        log_warning "In detached HEAD state. Checking out main/master branch..."
        if git show-ref --verify --quiet refs/heads/main; then
            git checkout main
            current_branch="main"
        elif git show-ref --verify --quiet refs/heads/master; then
            git checkout master
            current_branch="master"
        else
            die "Could not find main or master branch"
        fi
    fi

    log_info "Current branch: $current_branch"

    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_warning "You have uncommitted changes:"
        git status --short
        echo

        if ! safe_read "Do you want to continue? This will stash your changes. (y/N): " response "N"; then
            echo
            log_error "Failed to read input. Aborting."
            exit 1
        fi

        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            die "Aborted by user"
        fi
        git stash push -m "Auto-stash before update $(date)"
        log_info "Changes stashed"
    fi

    # Check if remote exists and fetch latest
    if git remote get-url origin &>/dev/null; then
        # Store pre-pull HEAD
        PRE_PULL_HEAD=$(git rev-parse HEAD)
        
        # Fetch latest changes first
        log_info "Fetching latest changes from origin..."
        if git fetch origin; then
            log_success "Successfully fetched latest changes"
            
            # Check if there are differences between local and remote
            local remote_branch="origin/${current_branch}"
            if git show-ref --verify --quiet "refs/remotes/${remote_branch}"; then
                local local_commit=$(git rev-parse HEAD)
                local remote_commit=$(git rev-parse "$remote_branch" 2>/dev/null || echo "")
                
                if [[ "$local_commit" != "$remote_commit" ]]; then
                    log_info "Differences detected between local ($local_commit) and remote ($remote_commit)"
                    
                    # Show what will be pulled
                    echo -e "\n${CYAN}Changes to be pulled:${NC}"
                    git log --oneline HEAD.."$remote_branch" 2>/dev/null || echo "Unable to show change log"
                    echo
                    
                    # Pull changes
                    log_info "Pulling changes from origin/$current_branch..."
                    if git pull; then
                        POST_PULL_HEAD=$(git rev-parse HEAD)
                        # Check if the pull actually changed anything
                        if [[ "$PRE_PULL_HEAD" != "$POST_PULL_HEAD" ]]; then
                            PULL_HAD_CHANGES=true
                            log_success "Successfully pulled latest changes (HEAD: $PRE_PULL_HEAD -> $POST_PULL_HEAD)"
                        else
                            log_info "Pull completed but no changes were made"
                        fi
                    else
                        log_warning "Failed to pull changes from remote. Continuing with current state..."
                        log_info "You may need to resolve conflicts manually later."
                    fi
                else
                    log_info "Local and remote are in sync - no changes to pull"
                fi
            else
                log_warning "Remote branch $remote_branch not found"
            fi
        else
            log_warning "Failed to fetch from remote. Continuing with local repository..."
        fi
    else
        log_warning "No remote 'origin' configured. Skipping pull operation."
        log_info "This appears to be a local-only repository."
    fi

    # Step 2: Handle smart dependencies (auto-enabled)
    log_header "Smart Dependency Management"
    log_info "Smart dependency management is enabled by default (use --no-deps to disable)"

    if [[ "$CHECK_DEPENDENCIES" == true ]]; then
        handle_dependencies
    else
        log_info "Smart dependency management disabled by user flag"
    fi

    # Step 3: Handle package rebuilding (if requested)
    if [[ "$CHECK_PACKAGES" == true ]]; then
        log_header "Package Updates"

        if [[ ! -d "$ARCH_PACKAGES_DIR" ]]; then
            log_warning "No arch-packages directory found. Skipping package updates."
        elif ! command -v makepkg >/dev/null 2>&1; then
            log_warning "makepkg not found. Cannot rebuild packages."
            log_info "Package rebuilding requires makepkg to be installed."
        elif ! command -v yay >/dev/null 2>&1; then
            log_warning "yay not found. Attempting to install yay for package management..."
            if [[ -f "${REPO_DIR}/scriptdata/installers" ]]; then
                source "${REPO_DIR}/scriptdata/environment-variables" 2>/dev/null || true
                source "${REPO_DIR}/scriptdata/functions" 2>/dev/null || true
                source "${REPO_DIR}/scriptdata/installers"
                if install-yay; then
                    log_success "yay installed successfully"
                    list_and_select_packages
                else
                    log_error "Failed to install yay. Cannot manage packages."
                fi
            else
                log_error "Cannot install yay automatically. Please install it manually or run install.sh"
            fi
        else
            list_and_select_packages
        fi
    else
        log_header "Package Updates"
        log_info "Package checking disabled. Use -p or --packages flag to enable package updates."

        # Still show a hint if there are changed PKGBUILDs
        if [[ -d "$ARCH_PACKAGES_DIR" ]]; then
            local changed_count=0
            for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
                if [[ -f "${pkg_dir}/PKGBUILD" ]] && check_pkgbuild_changed "$pkg_dir"; then
                    ((changed_count++))
                fi
            done

            if [[ $changed_count -gt 0 ]]; then
                log_warning "Note: $changed_count package(s) have changed PKGBUILDs since last update. Use -p flag to manage packages."
            fi
        fi
    fi

    # Step 4: Update configuration files (only changed ones)
    log_header "Smart Configuration File Updates"

    # Check if we should process files based on commit differences
    local process_files=false

    if [[ "$FORCE_CHECK" == true ]]; then
        process_files=true
        log_info "Force mode: checking all configuration files"
    elif [[ "$PULL_HAD_CHANGES" == true ]] || has_commit_differences; then
        process_files=true
        log_info "Changes detected: analyzing changed files..."
    else
        log_info "No changes detected, and not in force mode. Skipping file updates."
    fi

    if [[ "$process_files" == true ]]; then
        local sync_results
        sync_results=$(sync_config_files)
        read -r files_processed files_updated files_created files_skipped <<< "$sync_results"
        
        # Show processing summary
        echo
        log_info "Smart file processing summary:"
        log_info "- Files processed: $files_processed"
        log_info "- Files with conflicts/updates: $files_updated"
        log_info "- New files created: $files_created"
        log_info "- Files skipped (ignored/unchanged): $files_skipped"
    else
        log_info "Skipping file updates (no commit differences detected and not in force mode)"
        files_processed=0
        files_updated=0
        files_created=0
        files_skipped=0
    fi

    # Step 5: Update Python packages (if available and user wants to)
    log_header "Python Package Updates"

    if [[ -f "${REPO_DIR}/scriptdata/python-packages" ]]; then
        if safe_read "Update Python packages? (y/N): " update_python "N"; then
            if [[ "$update_python" =~ ^[Yy]$ ]]; then
                update_python_packages
            else
                log_info "Skipping Python package updates"
            fi
        fi
    else
        log_info "No Python packages configuration found"
    fi

    # Step 6: Reload Hyprland if running
    log_header "Reloading Services"

    # Reload Hyprland if running
    if pgrep -x "Hyprland" > /dev/null; then
        log_info "Reloading Hyprland configuration..."
        sleep 1
        if hyprctl reload 2>/dev/null; then
            log_success "Hyprland configuration reloaded"
        else
            log_warning "Could not reload Hyprland (this is normal if you're not in a Hyprland session)"
        fi
    else
        log_info "Hyprland is not running, skipping reload"
    fi

    # Step 7: Update Complete
    log_header "Smart Update Complete"
    log_success "Enhanced dotfiles smart update completed successfully!"

    # Show summary
    echo
    echo -e "${CYAN}Smart Update Summary:${NC}"
    echo "- Repository: $(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null || echo 'Unable to get commit info')"
    echo "- Branch: $current_branch"
    echo "- Mode: $([ "$FORCE_CHECK" == true ] && echo "Force check" || echo "Commit diff")"
    echo "- Smart dependencies: $([ "$CHECK_DEPENDENCIES" == true ] && echo "Enabled" || echo "Disabled")"
    echo "- Package updates: $([ "$CHECK_PACKAGES" == true ] && echo "Enabled" || echo "Disabled")"
    echo "- Auto-sync mode: $([ "$AUTO_SYNC_MODE" == true ] && echo "Enabled" || echo "Disabled")"

    if [[ "$process_files" == true ]]; then
        echo "- Files processed: $files_processed"
        echo "- Files updated/conflicted: $files_updated"
        echo "- New files created: $files_created"
        echo "- Files skipped: $files_skipped"
    fi

    echo "- Configuration directories: ${MONITOR_DIRS[*]}"

    # Environment variable warning (only if Hyprland configs were touched)
    if [[ -z "${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-}" && "$process_files" == true ]]; then
        echo
        echo -e "${YELLOW}Note: ILLOGICAL_IMPULSE_VIRTUAL_ENV environment variable is not set.${NC}"
        echo -e "${YELLOW}If Quickshell doesn't work, check ~/.config/hypr/hyprland/env.conf${NC}"
    fi

    # Information about configuration files
    echo
    echo -e "${CYAN}Configuration files:${NC}"
    echo "- ${UPDATE_IGNORE_FILE} or ${HOME_UPDATE_IGNORE_FILE} - files to ignore during updates"
    echo "- ${AUTO_SYNC_FILE} or ${HOME_AUTO_SYNC_FILE} - files to auto-sync without prompting"

    if [[ ! -f "$HOME_UPDATE_IGNORE_FILE" && ! -f "$UPDATE_IGNORE_FILE" ]]; then
        echo
        log_info "Tip: Create ignore files to exclude files from updates:"
        echo "  - Repository ignore: ${UPDATE_IGNORE_FILE}"
        echo "  - User ignore: ${HOME_UPDATE_IGNORE_FILE}"
    fi

    if [[ ! -f "$HOME_AUTO_SYNC_FILE" && ! -f "$AUTO_SYNC_FILE" ]]; then
        echo
        log_info "Tip: Create auto-sync files to automatically update certain files:"
        echo "  - Repository auto-sync: ${AUTO_SYNC_FILE}"
        echo "  - User auto-sync: ${HOME_AUTO_SYNC_FILE}"
    fi

    echo
}

# Run main function with all arguments
main "$@"
