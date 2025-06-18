#!/usr/bin/env bash
#
# update.sh - Enhanced dotfiles update script
#
# Features:
# - Pull latest commits from remote
# - Rebuild packages if PKGBUILD files changed (user choice)
# - Handle config file conflicts with user choices
# - Respect .updateignore file for exclusions
#
set -uo pipefail

# === Configuration ===
FORCE_CHECK=false
CHECK_PACKAGES=false
DETECT_ONLY=false
REPO_DIR="$(cd "$(dirname $0)" &>/dev/null && pwd)"
ARCH_PACKAGES_DIR="${REPO_DIR}/arch-packages"
UPDATE_IGNORE_FILE="${REPO_DIR}/.updateignore"
HOME_UPDATE_IGNORE_FILE="${HOME}/.updateignore"

# Directories to monitor for changes (matching install.sh behavior)
# These correspond to what install.sh copies to XDG directories
MONITOR_DIRS=(
  ".config"           # XDG_CONFIG_HOME
  ".local/bin"        # XDG_BIN_HOME  
  ".local/share"      # XDG_DATA_HOME
  ".local/state"      # XDG_STATE_HOME
  ".cache"            # XDG_CACHE_HOME
)

# Additional directories that install.sh handles specially
HYPRLAND_CONFIG_DIR=".config/hypr"
FISH_CONFIG_DIR=".config/fish"

# Files that install.sh handles with special logic (backup/conflict resolution)
SPECIAL_FILES=(
  ".config/hypr/hyprland.conf"
  ".config/hypr/hypridle.conf" 
  ".config/hypr/hyprlock.conf"
  ".config/hypr/custom"
)

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

  # Simple approach: just use read with /dev/tty and handle errors
  local input_value=""

  # Display prompt and read from terminal
  echo -n "$prompt"
  if read input_value </dev/tty 2>/dev/null || read input_value 2>/dev/null; then
    eval "$varname='$input_value'"
    return 0
  else
    # If read failed and we have a default, use it
    if [[ -n "$default" ]]; then
      echo
      log_warning "Using default: $default"
      eval "$varname='$default'"
      return 0
    else
      echo
      log_error "Failed to read input"
      return 1
    fi
  fi
}

# Function to check if a file should be ignored
should_ignore() {
  local file_path="$1"
  local relative_path="${file_path#$HOME/}"

  # Also get path relative to repo for repo-level ignores
  local repo_relative=""
  if [[ "$file_path" == "$REPO_DIR"* ]]; then
    repo_relative="${file_path#$REPO_DIR/}"
  fi

  # Check both repo and home ignore files
  for ignore_file in "$UPDATE_IGNORE_FILE" "$HOME_UPDATE_IGNORE_FILE"; do
    if [[ -f "$ignore_file" ]]; then
      while IFS= read -r pattern || [[ -n "$pattern" ]]; do
        # Skip empty lines and comments
        [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
        # Remove leading/trailing whitespace
        pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [[ -z "$pattern" ]] && continue

        # Handle different gitignore-style patterns
        local should_skip=false

        # Exact match
        if [[ "$relative_path" == "$pattern" ]] || [[ "$repo_relative" == "$pattern" ]]; then
          should_skip=true
        fi

        # Wildcard patterns (basic glob matching)
        if [[ "$relative_path" == $pattern ]] || [[ "$repo_relative" == $pattern ]]; then
          should_skip=true
        fi

        # Directory patterns (ending with /)
        if [[ "$pattern" == */ ]]; then
          local dir_pattern="${pattern%/}"
          if [[ "$relative_path" == "$dir_pattern"/* ]] || [[ "$repo_relative" == "$dir_pattern"/* ]]; then
            should_skip=true
          fi
        fi

        # Patterns starting with / (from root)
        if [[ "$pattern" == /* ]]; then
          local root_pattern="${pattern#/}"
          if [[ "$relative_path" == "$root_pattern" ]] || [[ "$relative_path" == "$root_pattern"/* ]] ||
            [[ "$repo_relative" == "$root_pattern" ]] || [[ "$repo_relative" == "$root_pattern"/* ]]; then
            should_skip=true
          fi
        fi

        # Patterns with wildcards
        if [[ "$pattern" == *"*"* ]]; then
          if [[ "$relative_path" == $pattern ]] || [[ "$repo_relative" == $pattern ]]; then
            should_skip=true
          fi
          # Also check if any parent directory matches
          local temp_path="$relative_path"
          while [[ "$temp_path" == */* ]]; do
            temp_path="${temp_path%/*}"
            if [[ "$temp_path" == $pattern ]]; then
              should_skip=true
              break
            fi
          done
        fi

        # Simple substring matching (for backward compatibility)
        if [[ ! "$should_skip" == true ]]; then
          if [[ "$file_path" == *"$pattern"* ]] || [[ "$relative_path" == *"$pattern"* ]]; then
            should_skip=true
          fi
        fi

        if [[ "$should_skip" == true ]]; then
          return 0
        fi
      done <"$ignore_file"
    fi
  done
  return 1
}

# Function to show file diff with syntax highlighting if possible
show_diff() {
  local file1="$1"
  local file2="$2"

  echo -e "\n${CYAN}Showing differences:${NC}"
  echo -e "${CYAN}Old file: $file1${NC}"
  echo -e "${CYAN}New file: $file2${NC}"
  echo "----------------------------------------"

  if command -v diff &>/dev/null; then
    diff -u "$file1" "$file2" || true
  else
    echo "diff command not available"
  fi
  echo "----------------------------------------"
}

# Function to handle file conflicts
handle_file_conflict() {
  local repo_file="$1"
  local home_file="$2"
  local filename=$(basename "$home_file")
  local dirname=$(dirname "$home_file")

  echo -e "\n${YELLOW}Conflict detected:${NC} $home_file"
  echo "Repository version differs from your local version."
  echo
  echo "Choose an action:"
  echo "1) Replace local file with repository version"
  echo "2) Keep local file unchanged"
  echo "3) Backup local file as ${filename}.old, use repository version"
  echo "4) Save repository version as ${filename}.new, keep local file"
  echo "5) Show diff and decide"
  echo "6) Skip this file"
  echo

  while true; do
    if ! safe_read "Enter your choice (1-6): " choice "6"; then
      echo
      log_warning "Failed to read input. Skipping file."
      return
    fi

    case $choice in
    1)
      cp -p "$repo_file" "$home_file"
      log_success "Replaced $home_file with repository version"
      break
      ;;
    2)
      log_info "Keeping local version of $home_file"
      break
      ;;
    3)
      mv "$home_file" "${dirname}/${filename}.old"
      cp -p "$repo_file" "$home_file"
      log_success "Backed up local file to ${filename}.old and updated with repository version"
      break
      ;;
    4)
      cp -p "$repo_file" "${dirname}/${filename}.new"
      log_success "Saved repository version as ${filename}.new, kept local file"
      break
      ;;
    5)
      show_diff "$home_file" "$repo_file"
      echo
      echo "After reviewing the diff, choose:"
      echo "r) Replace with repository version"
      echo "k) Keep local version"
      echo "b) Backup local and use repository version"
      echo "n) Save repository version as .new"
      echo "s) Skip this file"

      if ! safe_read "Enter your choice (r/k/b/n/s): " subchoice "s"; then
        echo
        log_warning "Failed to read input. Skipping file."
        return
      fi

      case $subchoice in
      r)
        cp -p "$repo_file" "$home_file"
        log_success "Replaced $home_file with repository version"
        break
        ;;
      k)
        log_info "Keeping local version of $home_file"
        break
        ;;
      b)
        mv "$home_file" "${dirname}/${filename}.old"
        cp -p "$repo_file" "$home_file"
        log_success "Backed up local file to ${filename}.old and updated"
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
      *)
        echo "Invalid choice. Please try again."
        ;;
      esac
      ;;
    6)
      log_info "Skipping $home_file"
      break
      ;;
    *)
      echo "Invalid choice. Please enter 1-6."
      ;;
    esac
  done
}

# Function to check if PKGBUILD has changed
check_pkgbuild_changed() {
  local pkg_dir="$1"
  local pkgbuild_path="${pkg_dir}/PKGBUILD"

  [[ ! -f "$pkgbuild_path" ]] && return 1

  # Get the path relative to repo
  local relative_path="${pkgbuild_path#$REPO_DIR/}"

  # If force check is enabled, always return true
  if [[ "$FORCE_CHECK" == true ]]; then
    return 0
  fi

  # Check if file changed in the last pull
  if git diff --name-only HEAD@{1} HEAD 2>/dev/null | grep -q "^${relative_path}$"; then
    return 0
  fi

  return 1
}

# Function to list available packages
list_packages() {
  local available_packages=()
  local changed_packages=()
  local outdated_packages=()
  local missing_packages=()

  if [[ ! -d "$ARCH_PACKAGES_DIR" ]]; then
    log_warning "No arch-packages directory found"
    return 1
  fi

  for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
    if [[ -f "${pkg_dir}/PKGBUILD" ]]; then
      local pkg_name=$(basename "$pkg_dir")
      available_packages+=("$pkg_name")

      # Check if PKGBUILD changed
      if check_pkgbuild_changed "$pkg_dir"; then
        changed_packages+=("$pkg_name")
      fi
      
      # Check if package needs updating
      if check_package_needs_update "$pkg_name" "$pkg_dir"; then
        if pacman -Q "$pkg_name" >/dev/null 2>&1; then
          outdated_packages+=("$pkg_name")
        else
          missing_packages+=("$pkg_name")
        fi
      fi
    fi
  done

  if [[ ${#available_packages[@]} -eq 0 ]]; then
    log_info "No packages found in arch-packages directory"
    return 1
  fi

  echo -e "\n${CYAN}Available packages:${NC}"
  for pkg in "${available_packages[@]}"; do
    local status=""
    local color=""
    
    if [[ " ${changed_packages[*]} " =~ " ${pkg} " ]]; then
      status=" (PKGBUILD changed)"
      color="${GREEN}●${NC}"
    elif [[ " ${outdated_packages[*]} " =~ " ${pkg} " ]]; then
      status=" (outdated)"
      color="${YELLOW}●${NC}"
    elif [[ " ${missing_packages[*]} " =~ " ${pkg} " ]]; then
      status=" (not installed)"
      color="${RED}●${NC}"
    else
      status=""
      color="○"
    fi
    
    echo -e "  ${color} ${pkg}${status}${NC}"
  done

  # Show summary
  if [[ ${#changed_packages[@]} -gt 0 ]]; then
    echo -e "\n${GREEN}Packages with changed PKGBUILDs: ${changed_packages[*]}${NC}"
  fi
  
  if [[ ${#outdated_packages[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Outdated packages: ${outdated_packages[*]}${NC}"
  fi
  
  if [[ ${#missing_packages[@]} -gt 0 ]]; then
    echo -e "${RED}Missing packages: ${missing_packages[*]}${NC}"
  fi

  return 0
}

# Function to build selected packages
build_packages() {
  local build_mode="$1" # "changed", "all", or "select"
  local packages_to_build=()
  local rebuilt_packages=0

  case "$build_mode" in
  "changed")
    for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
      if [[ -f "${pkg_dir}/PKGBUILD" ]]; then
        local pkg_name=$(basename "$pkg_dir")
        if check_pkgbuild_changed "$pkg_dir"; then
          packages_to_build+=("$pkg_name")
        fi
      fi
    done
    ;;
  "all")
    for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
      if [[ -f "${pkg_dir}/PKGBUILD" ]]; then
        local pkg_name=$(basename "$pkg_dir")
        packages_to_build+=("$pkg_name")
      fi
    done
    ;;
  "select")
    echo -e "\nEnter package names separated by spaces (or 'all' for all packages):"
    if ! safe_read "Packages to build: " user_selection ""; then
      log_warning "Failed to read input. Skipping package builds."
      return
    fi

    if [[ "$user_selection" == "all" ]]; then
      for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
        if [[ -f "${pkg_dir}/PKGBUILD" ]]; then
          local pkg_name=$(basename "$pkg_dir")
          packages_to_build+=("$pkg_name")
        fi
      done
    else
      read -ra packages_to_build <<<"$user_selection"
    fi
    ;;
  esac

  if [[ ${#packages_to_build[@]} -eq 0 ]]; then
    log_info "No packages selected for building"
    return
  fi

  echo -e "\n${CYAN}Packages to build: ${packages_to_build[*]}${NC}"

  if ! safe_read "Proceed with building these packages? (Y/n): " confirm "Y"; then
    log_warning "Failed to read input. Skipping package builds."
    return
  fi

  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    log_info "Package building cancelled by user"
    return
  fi

  for pkg_name in "${packages_to_build[@]}"; do
    local pkg_dir="${ARCH_PACKAGES_DIR}/${pkg_name}"

    if [[ ! -d "$pkg_dir" || ! -f "${pkg_dir}/PKGBUILD" ]]; then
      log_error "Package not found or missing PKGBUILD: $pkg_name"
      continue
    fi

    log_info "Building package: $pkg_name"
    cd "$pkg_dir" || continue

    if makepkg -si --noconfirm; then
      log_success "Successfully built and installed $pkg_name"
      ((rebuilt_packages++))
    else
      log_error "Failed to build package $pkg_name"
    fi

    cd "$REPO_DIR" || die "Failed to return to repository directory"
  done

  if [[ $rebuilt_packages -eq 0 ]]; then
    log_warning "No packages were successfully built"
  else
    log_success "Successfully rebuilt $rebuilt_packages package(s)"
  fi
}

# Function to get list of changed files since last pull or all files if force check
get_changed_files() {
  local dir_path="$1"

  if [[ "$FORCE_CHECK" == true ]]; then
    # Return all files in the directory
    find "$dir_path" -type f -print0 2>/dev/null
  else
    # Get files that changed in the last pull
    local changed_files=()
    while IFS= read -r file; do
      local full_path="${REPO_DIR}/${file}"
      # Check if file is in the directory we're processing
      if [[ "$full_path" == "$dir_path"/* ]] && [[ -f "$full_path" ]]; then
        printf '%s\0' "$full_path"
      fi
    done < <(git diff --name-only HEAD@{1} HEAD 2>/dev/null || true)

    # If no files changed via git, but force_check is false, still check all files
    # This handles the case where there were no new commits but files might differ
    if ! git diff --quiet HEAD@{1} HEAD 2>/dev/null; then
      : # Files were found via git diff
    else
      # No git changes detected, check all files anyway for local differences
      find "$dir_path" -type f -print0 2>/dev/null
    fi
  fi
}

# Function to check if we have new commits
has_new_commits() {
  # Check if HEAD@{1} exists (meaning there was a previous commit)
  if git rev-parse --verify HEAD@{1} &>/dev/null; then
    # Check if HEAD and HEAD@{1} are different
    [[ "$(git rev-parse HEAD)" != "$(git rev-parse HEAD@{1})" ]]
  else
    # No previous commit reference, assume we have commits
    return 0
  fi
}

# Enhanced detection functions
# Function to check if a file is different using multiple methods
check_file_difference() {
  local repo_file="$1"
  local home_file="$2"
  
  # Method 1: Binary comparison (fastest)
  if ! cmp -s "$repo_file" "$home_file" 2>/dev/null; then
    return 0  # Files are different
  fi
  
  # Method 2: Check file modification times (if available)
  if [[ -f "$repo_file" && -f "$home_file" ]]; then
    local repo_mtime=$(stat -c %Y "$repo_file" 2>/dev/null || echo "0")
    local home_mtime=$(stat -c %Y "$home_file" 2>/dev/null || echo "0")
    
    # If repo file is newer, it might be different
    if [[ $repo_mtime -gt $home_mtime ]]; then
      # Double-check with diff to be sure
      if ! diff -q "$repo_file" "$home_file" >/dev/null 2>&1; then
        return 0  # Files are different
      fi
    fi
  fi
  
  return 1  # Files are the same
}

# Function to check if a package needs updating
check_package_needs_update() {
  local pkg_name="$1"
  local pkg_dir="$2"
  
  # Check if package is installed
  if ! pacman -Q "$pkg_name" >/dev/null 2>&1; then
    return 0  # Package not installed, needs installation
  fi
  
  # Get installed version
  local installed_version=$(pacman -Q "$pkg_name" | awk '{print $2}')
  
  # Get version from PKGBUILD
  if [[ -f "${pkg_dir}/PKGBUILD" ]]; then
    cd "$pkg_dir" || return 1
    source ./PKGBUILD 2>/dev/null || return 1
    
    # Compare versions (basic string comparison)
    if [[ "$installed_version" != "$pkgver" ]]; then
      cd "$REPO_DIR" || return 1
      return 0  # Version mismatch, needs update
    fi
    
    cd "$REPO_DIR" || return 1
  fi
  
  return 1  # Package is up to date
}

# Function to detect all differences comprehensively
detect_all_differences() {
  local differences=()
  local repo_file="$1"
  local home_file="$2"
  local rel_path="$3"
  
  # Only process files that exist in the repository
  if [[ ! -f "$repo_file" ]]; then
    return 1  # Not a repo file, skip
  fi
  
  # Check if file exists in both locations
  if [[ -f "$repo_file" && -f "$home_file" ]]; then
    # Check for content differences
    if check_file_difference "$repo_file" "$home_file"; then
      differences+=("content")
    fi
    
    # Check for permission differences
    local repo_perm=$(stat -c %a "$repo_file" 2>/dev/null || echo "644")
    local home_perm=$(stat -c %a "$home_file" 2>/dev/null || echo "644")
    if [[ "$repo_perm" != "$home_perm" ]]; then
      differences+=("permissions")
    fi
    
    # Check for ownership differences (if running as root)
    if [[ $EUID -eq 0 ]]; then
      local repo_owner=$(stat -c %U "$repo_file" 2>/dev/null || echo "")
      local home_owner=$(stat -c %U "$home_file" 2>/dev/null || echo "")
      if [[ "$repo_owner" != "$home_owner" ]]; then
        differences+=("ownership")
      fi
    fi
  elif [[ -f "$repo_file" && ! -f "$home_file" ]]; then
    differences+=("missing")
  fi
  
  echo "${differences[*]}"
}

# Function to get comprehensive file list for comparison
get_comprehensive_file_list() {
  local dir_path="$1"
  local file_list=()
  
  if [[ "$FORCE_CHECK" == true ]]; then
    # Get all files in the repository directory
    while IFS= read -r -d '' file; do
      file_list+=("$file")
    done < <(find "$dir_path" -type f -print0 2>/dev/null)
  else
    # Get files that changed in git
    while IFS= read -r file; do
      local full_path="${REPO_DIR}/${file}"
      if [[ "$full_path" == "$dir_path"/* ]] && [[ -f "$full_path" ]]; then
        file_list+=("$full_path")
      fi
    done < <(git diff --name-only HEAD@{1} HEAD 2>/dev/null || true)
    
    # If no git changes detected, check all files in repo for local differences
    # This handles the case where there were no new commits but files might differ
    if [[ ${#file_list[@]} -eq 0 ]]; then
      # No git changes, check all files in repo for differences with local versions
      while IFS= read -r -d '' file; do
        local rel_path="${file#$REPO_DIR/}"
        local home_file="${HOME}/${rel_path}"
        
        # Only include if home file exists and is different from repo file
        if [[ -f "$home_file" ]] && check_file_difference "$file" "$home_file"; then
          file_list+=("$file")
        fi
      done < <(find "$dir_path" -type f -print0 2>/dev/null)
    fi
  fi
  
  # Remove duplicates and return
  printf '%s\n' "${file_list[@]}" | sort -u
}

# Function to handle special files (like hyprland.conf, hypridle.conf, etc.)
handle_special_file() {
  local repo_file="$1"
  local home_file="$2"
  local filename=$(basename "$home_file")
  local dirname=$(dirname "$home_file")
  local rel_path="${home_file#$HOME/}"

  # Check if this is a special file that needs special handling
  local is_special=false
  for special_file in "${SPECIAL_FILES[@]}"; do
    if [[ "$rel_path" == "$special_file" ]]; then
      is_special=true
      break
    fi
  done

  if [[ "$is_special" == false ]]; then
    return 1  # Not a special file, handle normally
  fi

  echo -e "\n${CYAN}Special file detected: $rel_path${NC}"
  echo "This file is handled specially by the install script."
  echo "Choose an action:"
  echo "1) Apply install.sh logic (backup existing, use repo version)"
  echo "2) Handle like a normal file conflict"
  echo "3) Skip this file"
  echo

  if ! safe_read "Enter your choice (1-3): " choice "1"; then
    echo
    log_warning "Failed to read input. Using install.sh logic."
    choice="1"
  fi

  case $choice in
    1)
      # Apply install.sh logic
      if [[ -f "$home_file" ]]; then
        # Backup existing file
        mv "$home_file" "${dirname}/${filename}.old"
        log_success "Backed up existing file to ${filename}.old"
      fi
      # Copy repo version
      cp -p "$repo_file" "$home_file"
      log_success "Applied repository version of $rel_path"
      ;;
    2)
      # Handle like normal conflict
      handle_file_conflict "$repo_file" "$home_file"
      ;;
    3)
      log_info "Skipping special file: $rel_path"
      ;;
    *)
      log_warning "Invalid choice. Using install.sh logic."
      # Apply install.sh logic as fallback
      if [[ -f "$home_file" ]]; then
        mv "$home_file" "${dirname}/${filename}.old"
        log_success "Backed up existing file to ${filename}.old"
      fi
      cp -p "$repo_file" "$home_file"
      log_success "Applied repository version of $rel_path"
      ;;
  esac

  return 0  # Special file handled
}

# Function to generate comprehensive detection report
generate_detection_report() {
  local report_file="${REPO_DIR}/update-detection-report.txt"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo "=== Dotfiles Update Detection Report ===" > "$report_file"
  echo "Generated: $timestamp" >> "$report_file"
  echo "Repository: $(git rev-parse --show-toplevel)" >> "$report_file"
  echo "Branch: $(git branch --show-current)" >> "$report_file"
  echo "Commit: $(git rev-parse HEAD)" >> "$report_file"
  echo "" >> "$report_file"
  
  # Package detection report
  echo "=== PACKAGE DETECTION ===" >> "$report_file"
  if [[ -d "$ARCH_PACKAGES_DIR" ]]; then
    local changed_pkgs=()
    local outdated_pkgs=()
    local missing_pkgs=()
    
    for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
      if [[ -f "${pkg_dir}/PKGBUILD" ]]; then
        local pkg_name=$(basename "$pkg_dir")
        
        if check_pkgbuild_changed "$pkg_dir"; then
          changed_pkgs+=("$pkg_name")
        fi
        
        if check_package_needs_update "$pkg_name" "$pkg_dir"; then
          if pacman -Q "$pkg_name" >/dev/null 2>&1; then
            outdated_pkgs+=("$pkg_name")
          else
            missing_pkgs+=("$pkg_name")
          fi
        fi
      fi
    done
    
    echo "Packages with changed PKGBUILDs: ${changed_pkgs[*]}" >> "$report_file"
    echo "Outdated packages: ${outdated_pkgs[*]}" >> "$report_file"
    echo "Missing packages: ${missing_pkgs[*]}" >> "$report_file"
  else
    echo "No arch-packages directory found" >> "$report_file"
  fi
  echo "" >> "$report_file"
  
  # File detection report
  echo "=== FILE DETECTION ===" >> "$report_file"
  local total_files=0
  local content_diffs=0
  local perm_diffs=0
  local missing_files=0
  local extra_files=0
  
  for dir_name in "${MONITOR_DIRS[@]}"; do
    repo_dir_path="${REPO_DIR}/${dir_name}"
    home_dir_path="${HOME}/${dir_name}"
    
    if [[ ! -d "$repo_dir_path" ]]; then
      echo "Directory not found: $repo_dir_path" >> "$report_file"
      continue
    fi
    
    echo "Scanning: $dir_name" >> "$report_file"
    
    while IFS= read -r repo_file; do
      rel_path="${repo_file#$repo_dir_path/}"
      home_file="${home_dir_path}/${rel_path}"
      
      if should_ignore "$home_file"; then
        continue
      fi
      
      ((total_files++))
      local differences=$(detect_all_differences "$repo_file" "$home_file" "$rel_path")
      
      if [[ -n "$differences" ]]; then
        echo "  $rel_path: $differences" >> "$report_file"
        
        for diff_type in $differences; do
          case $diff_type in
            "content") ((content_diffs++)) ;;
            "permissions") ((perm_diffs++)) ;;
            "missing") ((missing_files++)) ;;
            "extra") ((extra_files++)) ;;
          esac
        done
      fi
    done < <(get_comprehensive_file_list "$repo_dir_path")
  done
  
  echo "" >> "$report_file"
  echo "=== SUMMARY ===" >> "$report_file"
  echo "Total files scanned: $total_files" >> "$report_file"
  echo "Files with content differences: $content_diffs" >> "$report_file"
  echo "Files with permission differences: $perm_diffs" >> "$report_file"
  echo "Missing files: $missing_files" >> "$report_file"
  echo "Extra files: $extra_files" >> "$report_file"
  
  log_info "Detection report saved to: $report_file"
  return 0
}

# Main script starts here
log_header "Dotfiles Update Script"

check=true

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
  -d | --detect-only)
    DETECT_ONLY=true
    log_info "Detection only mode enabled - will generate a detection report without making changes"
    shift
    ;;
  -h | --help)
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --force      Force check all files even if no new commits"
    echo "  -p, --packages   Enable package checking and building"
    echo "  -d, --detect-only Enable detection only mode"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "This script updates your dotfiles by:"
    echo "  1. Pulling latest changes from git remote"
    echo "  2. Optionally rebuilding packages (if -p flag is used)"
    echo "  3. Syncing configuration files"
    echo "  4. Updating script permissions"
    echo ""
    echo "Package modes (when -p is used):"
    echo "  - If no PKGBUILDs changed: asks if you want to check packages anyway"
    echo "  - If PKGBUILDs changed: offers to build changed packages"
    echo "  - Interactive selection of packages to build"
    echo ""
    echo "Detection modes:"
    echo "  - Normal mode: detects and applies changes"
    echo "  - Detection-only mode (-d): generates a report without making changes"
    echo "  - Force mode (-f): checks all files regardless of git changes"
    exit 0
    ;;
  --skip-notice)
    log_warning "Skipping notice about script being untested"
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
  safe_read "BY CONTINUE YOU WILL USE IT AT YOUR OWN RISK (y/N): " response "N"

  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_error "Update aborted by user"
    exit 1
  fi
fi

# Check if we're in a git repository
cd "$REPO_DIR" || die "Failed to change to repository directory"

if git rev-parse --is-inside-work-tree &>/dev/null; then
  log_info "Running in git repository: $(git rev-parse --show-toplevel)"
else
  log_error "Not in a git repository. Please run this script from your dotfiles repository."
  exit 1
fi

# Step 1: Pull latest commits
log_header "Pulling Latest Changes"

# Check current branch
current_branch=$(git branch --show-current)
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

# Check for uncommitted changes
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

# Check if remote exists
if git remote get-url origin &>/dev/null; then
  # Pull changes
  log_info "Pulling changes from origin/$current_branch..."
  if git pull; then
    log_success "Successfully pulled latest changes"
  else
    log_warning "Failed to pull changes from remote. Continuing with local repository..."
    log_info "You may need to resolve conflicts manually later."
  fi
else
  log_warning "No remote 'origin' configured. Skipping pull operation."
  log_info "This appears to be a local-only repository."
fi

# If in detection-only mode, generate report and exit
if [[ "$DETECT_ONLY" == true ]]; then
  log_header "Detection Only Mode"
  log_info "Generating comprehensive detection report..."
  generate_detection_report
  
  echo
  log_success "Detection report generated successfully!"
  echo "Report saved to: ${REPO_DIR}/update-detection-report.txt"
  echo
  echo "To apply changes, run the script without --detect-only flag"
  exit 0
fi

# Step 2: Handle package building (only if requested)
rebuilt_packages=0

if [[ "$CHECK_PACKAGES" == true ]]; then
  log_header "Package Management"

  if [[ ! -d "$ARCH_PACKAGES_DIR" ]]; then
    log_warning "No arch-packages directory found. Skipping package management."
  else
    # Check if any PKGBUILDs have changed
    changed_pkgbuilds=()
    for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
      if [[ -f "${pkg_dir}/PKGBUILD" ]]; then
        local pkg_name=$(basename "$pkg_dir")
        if check_pkgbuild_changed "$pkg_dir"; then
          changed_pkgbuilds+=("$pkg_name")
        fi
      fi
    done

    if [[ ${#changed_pkgbuilds[@]} -gt 0 ]]; then
      log_info "Found ${#changed_pkgbuilds[@]} package(s) with changed PKGBUILDs: ${changed_pkgbuilds[*]}"
      echo
      echo "Package build options:"
      echo "1) Build only packages with changed PKGBUILDs"
      echo "2) List all packages and select which to build"
      echo "3) Build all packages"
      echo "4) Skip package building"
      echo

      if safe_read "Choose an option (1-4): " pkg_choice "1"; then
        case $pkg_choice in
        1)
          build_packages "changed"
          ;;
        2)
          if list_packages; then
            build_packages "select"
          fi
          ;;
        3)
          build_packages "all"
          ;;
        4 | *)
          log_info "Skipping package building"
          ;;
        esac
      else
        log_warning "Failed to read input. Skipping package building."
      fi
    else
      log_info "No PKGBUILDs have changed since last update."
      echo
      if safe_read "Do you want to check and build packages anyway? (y/N): " check_anyway "N"; then
        if [[ "$check_anyway" =~ ^[Yy]$ ]]; then
          if list_packages; then
            echo
            echo "Package build options:"
            echo "1) Select specific packages to build"
            echo "2) Build all packages"
            echo "3) Skip package building"

            if safe_read "Choose an option (1-3): " build_choice "3"; then
              case $build_choice in
              1)
                build_packages "select"
                ;;
              2)
                build_packages "all"
                ;;
              3 | *)
                log_info "Skipping package building"
                ;;
              esac
            else
              log_info "Skipping package building"
            fi
          fi
        else
          log_info "Skipping package management"
        fi
      else
        log_info "Skipping package management"
      fi
    fi
  fi
else
  log_header "Package Management"
  log_info "Package checking disabled. Use -p or --packages flag to enable package management."

  # Still show a hint if there are changed PKGBUILDs
  if [[ -d "$ARCH_PACKAGES_DIR" ]]; then
    changed_count=0
    for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
      if [[ -f "${pkg_dir}/PKGBUILD" ]] && check_pkgbuild_changed "$pkg_dir"; then
        ((changed_count++))
      fi
    done

    if [[ $changed_count -gt 0 ]]; then
      log_warning "Note: $changed_count package(s) have changed PKGBUILDs. Use -p flag to manage packages."
    fi
  fi
fi

# Step 3: Update configuration files
log_header "Updating Configuration Files"

# Check if we should process files
process_files=false
if [[ "$FORCE_CHECK" == true ]]; then
  process_files=true
  log_info "Force mode: checking all configuration files"
elif has_new_commits; then
  process_files=true
  log_info "New commits detected: checking changed configuration files"
else
  log_info "No new commits found: checking for local file differences"
  process_files=true # Always check for differences even without commits
fi

if [[ "$process_files" == true ]]; then
  files_processed=0
  files_updated=0
  files_created=0
  files_skipped=0
  files_with_permission_changes=0

  for dir_name in "${MONITOR_DIRS[@]}"; do
    repo_dir_path="${REPO_DIR}/${dir_name}"
    home_dir_path="${HOME}/${dir_name}"

    if [[ ! -d "$repo_dir_path" ]]; then
      log_warning "Repository directory not found: $repo_dir_path"
      continue
    fi

    log_info "Processing directory: $dir_name"

    # Create home directory if it doesn't exist
    mkdir -p "$home_dir_path"

    # Get comprehensive file list for comparison
    while IFS= read -r repo_file; do
      # Calculate relative path and corresponding home file path
      rel_path="${repo_file#$repo_dir_path/}"
      home_file="${home_dir_path}/${rel_path}"

      # Check if file should be ignored
      if should_ignore "$home_file"; then
        ((files_skipped++))
        continue
      fi

      ((files_processed++))

      # Create directory structure if needed
      mkdir -p "$(dirname "$home_file")"

      # Detect all types of differences
      differences=$(detect_all_differences "$repo_file" "$home_file" "$rel_path")
      
      if [[ -n "$differences" ]]; then
        # Parse differences
        has_content_diff=false
        has_perm_diff=false
        is_missing=false
        is_extra=false
        
        for diff_type in $differences; do
          case $diff_type in
            "content") has_content_diff=true ;;
            "permissions") has_perm_diff=true ;;
            "missing") is_missing=true ;;
            "extra") is_extra=true ;;
          esac
        done
        
        # Handle different types of differences
        if [[ "$is_missing" == true ]]; then
          # New file, copy it
          cp -p "$repo_file" "$home_file"
          log_success "Created new file: $rel_path"
          ((files_created++))
        elif [[ "$has_content_diff" == true ]]; then
          # Content difference, check if it's a special file first
          if ! handle_special_file "$repo_file" "$home_file"; then
            # Not a special file, handle as normal conflict
            handle_file_conflict "$repo_file" "$home_file"
          fi
          ((files_updated++))
        elif [[ "$has_perm_diff" == true ]]; then
          # Permission difference only
          chmod --reference="$repo_file" "$home_file" 2>/dev/null || true
          log_info "Fixed permissions for: $rel_path"
          ((files_with_permission_changes++))
        fi
      fi
    done < <(get_comprehensive_file_list "$repo_dir_path")
  done

  # Show processing summary
  echo
  log_info "File processing summary:"
  log_info "- Files processed: $files_processed"
  log_info "- Files with conflicts: $files_updated"
  log_info "- New files created: $files_created"
  log_info "- Files with permission fixes: $files_with_permission_changes"
  log_info "- Files skipped (ignored): $files_skipped"
else
  log_info "Skipping file updates (no changes detected and not in force mode)"
fi

# Step 4: Update script permissions
log_header "Updating Script Permissions"

if [[ -d "${REPO_DIR}/scriptdata" ]]; then
  find "${REPO_DIR}/scriptdata" -type f -name "*.sh" -exec chmod +x {} \;
  find "${REPO_DIR}/scriptdata" -type f -executable -exec chmod +x {} \;
  log_success "Updated script permissions"
fi

# Make sure local bin scripts are executable
if [[ -d "${HOME}/.local/bin" ]]; then
  find "${HOME}/.local/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
  log_success "Updated ~/.local/bin script permissions"
fi

log_header "Update Complete"
log_success "Dotfiles update completed successfully!"

# Show summary
echo
echo -e "${CYAN}Summary:${NC}"
echo "- Repository: $(git log -1 --pretty=format:'%h - %s (%cr)')"
echo "- Branch: $current_branch"
echo "- Mode: $([ "$FORCE_CHECK" == true ] && echo "Force check" || echo "Normal")"
echo "- Detection mode: $([ "$DETECT_ONLY" == true ] && echo "Detection only" || echo "Apply changes")"
echo "- Package checking: $([ "$CHECK_PACKAGES" == true ] && echo "Enabled" || echo "Disabled")"

if [[ $rebuilt_packages -gt 0 ]]; then
  echo "- Packages rebuilt: $rebuilt_packages"
fi

if [[ "$process_files" == true ]]; then
  echo "- Files processed: $files_processed"
  echo "- Files updated/conflicted: $files_updated"
  echo "- New files created: $files_created"
  echo "- Files with permission fixes: $files_with_permission_changes"
  echo "- Files skipped (ignored): $files_skipped"
fi

echo "- Configuration directories: ${MONITOR_DIRS[*]}"

# Remind about ignore files and show examples
if [[ ! -f "$HOME_UPDATE_IGNORE_FILE" && ! -f "$UPDATE_IGNORE_FILE" ]]; then
  echo
  log_info "Tip: Create ignore files to exclude files from updates:"
  echo "  - Repository ignore: ${REPO_DIR}/.updateignore"
  echo "  - User ignore: ~/.updateignore"
  echo
  echo "Example patterns:"
  echo "  *.log                 # Ignore all .log files"
  echo "  .config/personal/     # Ignore entire directory"
  echo "  secret-config.conf    # Ignore specific file"
  echo "  /temp-file            # Ignore from root only"
  echo "  *secret*              # Ignore files containing 'secret'"
fi

echo
