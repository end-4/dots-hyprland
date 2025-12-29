# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

#####################################################################################
# Notes by @clsty:
#
# I'm not the one who developed this script (see issue#2284 which discussed about the history).
# However it contains many unnecessary logics. This is typically what AI will do.
# I don't really care if it's AI-generated or not, it's just an extra option in addition to ./setup install, so as long as the users say it works, it should be fine.
# However, it's not easy to maintain something like this.
# The redundant logic should be cleaned up someday.
#
# This also applies for exp-update.tester.sh, TBH I don't think that file is really needed, and it also looks like AI-generated. Just guessing though.
#####################################################################################
#
# exp-update.sh - Enhanced dotfiles update script
#
# Features:
# - Auto-detect repository structure (dots/ prefix or direct config)
# - Pull latest commits from remote
# - Rebuild packages if PKGBUILD files changed (user choice)
# - Handle config file conflicts with user choices
# - Respect .updateignore file for exclusions with flexible pattern matching:
#   - Exact matches (e.g., "path/to/file")
#   - Directory patterns (e.g., "path/to/dir/")
#   - Wildcards (e.g., "*.log", "path/*/file")
#   - Root-relative patterns (e.g., "/.config")
#   - Substring matching (prefix with "**", e.g., "**temp" matches any path containing "temp")
#
set -euo pipefail

# Note: The detect_repo_structure function below auto-detects the folder layout
# Try to find the packages directory (different names in different versions)
if which pacman &>/dev/null; then
  if [[ -d "${REPO_ROOT}/dist-arch" ]]; then
    ARCH_PACKAGES_DIR="${REPO_ROOT}/dist-arch"
  elif [[ -d "${REPO_ROOT}/arch-packages" ]]; then
    ARCH_PACKAGES_DIR="${REPO_ROOT}/arch-packages"
  elif [[ -d "${REPO_ROOT}/sdata/dist-arch" ]]; then
    ARCH_PACKAGES_DIR="${REPO_ROOT}/sdata/dist-arch"
  else
    ARCH_PACKAGES_DIR="${REPO_ROOT}/dist-arch"  # Default fallback
  fi
fi
UPDATE_IGNORE_FILE="${REPO_ROOT}/.updateignore"
HOME_UPDATE_IGNORE_FILE="${HOME}/.updateignore"

# Global arrays for cached ignore patterns (performance optimization)
declare -a IGNORE_PATTERNS=()
declare -a IGNORE_SUBSTRING_PATTERNS=()

# Track created directories to avoid redundant mkdir calls
declare -A CREATED_DIRS

# Auto-detect repository structure
detect_repo_structure() {
  local found_dirs=()
  
  # Check for dots/ prefixed structure
  if [[ -d "${REPO_ROOT}/dots/.config" ]]; then
    found_dirs+=("dots/.config")
    [[ -d "${REPO_ROOT}/dots/.local/bin" ]] && found_dirs+=("dots/.local/bin")
    [[ -d "${REPO_ROOT}/dots/.local/share" ]] && found_dirs+=("dots/.local/share")
  # Check for flat structure
  elif [[ -d "${REPO_ROOT}/.config" ]]; then
    found_dirs+=(".config")
    [[ -d "${REPO_ROOT}/.local/bin" ]] && found_dirs+=(".local/bin")
    [[ -d "${REPO_ROOT}/.local/share" ]] && found_dirs+=(".local/share")
  else
    # Manual detection of common directories
    for candidate in "dots/.config" ".config" "dots/.local/bin" ".local/bin" "dots/.local/share" ".local/share"; do
      if [[ -d "${REPO_ROOT}/${candidate}" ]]; then
        # Avoid duplicates
        if [[ ! " ${found_dirs[*]} " =~ " ${candidate} " ]]; then
          found_dirs+=("${candidate}")
        fi
      fi
    done
  fi
  
  if [[ ${#found_dirs[@]} -eq 0 ]]; then
    echo "ERROR: Could not detect repository structure" >&2
    return 1
  fi
  
  echo "${found_dirs[@]}"
}

# Directories to monitor for changes (will be auto-detected)
MONITOR_DIRS=()

# Enhanced safe_read with better terminal handling
safe_read() {
  local prompt="$1"
  local varname="$2"
  local default="${3:-}"
  local input_value=""

  # In non-interactive mode, use default immediately
  if [[ "$NON_INTERACTIVE" == true ]]; then
    if [[ -n "$default" ]]; then
      printf -v "$varname" '%s' "$default"
      return 0
    else
      log_error "Non-interactive mode requires default value for: $prompt"
      return 1
    fi
  fi

  echo -n "$prompt"
  
  # Try to read from terminal with better detection
  if [[ -t 0 ]]; then
    # stdin is a terminal
    read -r input_value
  elif [[ -r /dev/tty ]]; then
    # Try reading from tty
    if read -r input_value </dev/tty 2>/dev/null; then
      : # Success
    else
      input_value=""
    fi
  else
    # No interactive terminal available
    if [[ -n "$default" ]]; then
      echo
      log_warning "No terminal available. Using default: $default"
      printf -v "$varname" '%s' "$default"
      return 0
    else
      echo
      log_error "No terminal available and no default provided"
      return 1
    fi
  fi

  if [[ -n "$input_value" ]]; then
    printf -v "$varname" '%s' "$input_value"
    return 0
  elif [[ -n "$default" ]]; then
    echo
    log_warning "Empty input. Using default: $default"
    printf -v "$varname" '%s' "$default"
    return 0
  else
    echo
    log_error "Input required but not provided"
    return 1
  fi
}

# Load and cache ignore patterns for performance
load_ignore_patterns() {
  IGNORE_PATTERNS=()
  IGNORE_SUBSTRING_PATTERNS=()
  
  for ignore_file in "$UPDATE_IGNORE_FILE" "$HOME_UPDATE_IGNORE_FILE"; do
    [[ ! -f "$ignore_file" ]] && continue
    
    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
      # Skip empty lines and comments
      [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
      # Remove whitespace
      pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      [[ -z "$pattern" ]] && continue
      
      # Separate substring patterns from regular patterns
      if [[ "${pattern:0:2}" == "**" ]]; then
        local cleaned_pattern="${pattern#\*\*}"
        # Strip trailing asterisks
        while [[ "$cleaned_pattern" == *"*" ]] && [[ "${cleaned_pattern: -1}" == "*" ]]; do
          cleaned_pattern="${cleaned_pattern%\*}"
        done
        # Ensure we have a non-empty pattern
        if [[ -n "$cleaned_pattern" ]]; then
          IGNORE_SUBSTRING_PATTERNS+=("$cleaned_pattern")
        fi
      else
        IGNORE_PATTERNS+=("$pattern")
      fi
    done < "$ignore_file"
  done
  
  if [[ "$VERBOSE" == true ]]; then
    log_info "Loaded ${#IGNORE_PATTERNS[@]} ignore patterns and ${#IGNORE_SUBSTRING_PATTERNS[@]} substring patterns"
  fi
}

# Optimized should_ignore using cached patterns
should_ignore() {
  local file_path="$1"
  local relative_path="${file_path#$HOME/}"
  local repo_relative=""
  
  if [[ "$file_path" == "$REPO_ROOT"* ]]; then
    repo_relative="${file_path#$REPO_ROOT/}"
  fi

  # Check regular patterns
  for pattern in "${IGNORE_PATTERNS[@]}"; do
    # Exact match
    if [[ "$relative_path" == "$pattern" ]] || [[ "$repo_relative" == "$pattern" ]]; then
      return 0
    fi

    # Wildcard patterns (basic glob matching)
    if [[ "$relative_path" == $pattern ]] || [[ "$repo_relative" == $pattern ]]; then
      return 0
    fi

    # Directory patterns (ending with /)
    if [[ "$pattern" == */ ]]; then
      local dir_pattern="${pattern%/}"
      if [[ "$relative_path" == "$dir_pattern"/* ]] || [[ "$repo_relative" == "$dir_pattern"/* ]]; then
        return 0
      fi
    fi

    # Root-relative patterns (starting with /)
    if [[ "$pattern" == /* ]]; then
      local root_pattern="${pattern#/}"
      if [[ "$relative_path" == "$root_pattern" ]] || [[ "$relative_path" == "$root_pattern"/* ]] ||
         [[ "$repo_relative" == "$root_pattern" ]] || [[ "$repo_relative" == "$root_pattern"/* ]]; then
        return 0
      fi
    fi

    # Patterns with wildcards - check parent directories
    if [[ "$pattern" == *"*"* ]]; then
      local temp_path="$relative_path"
      while [[ "$temp_path" == */* ]]; do
        temp_path="${temp_path%/*}"
        if [[ "$temp_path" == $pattern ]]; then
          return 0
        fi
      done
    fi
  done

  # Check substring patterns
  for substring in "${IGNORE_SUBSTRING_PATTERNS[@]}"; do
    if [[ -n "$substring" && ("$file_path" == *"$substring"* || "$relative_path" == *"$substring"*) ]]; then
      return 0
    fi
  done

  return 1
}

# Efficient directory creation with caching
ensure_directory() {
  local dir="$1"
  
  # Check if already created in this run
  if [[ -n "${CREATED_DIRS[$dir]:-}" ]]; then
    return 0
  fi
  
  if [[ "$DRY_RUN" != true ]]; then
    if [[ ! -d "$dir" ]]; then
      if mkdir -p "$dir" 2>/dev/null; then
        CREATED_DIRS[$dir]=1
        if [[ "$VERBOSE" == true ]]; then
          log_info "Created directory: $dir"
        fi
      else
        log_error "Failed to create directory: $dir"
        return 1
      fi
    else
      CREATED_DIRS[$dir]=1
    fi
  else
    if [[ "$VERBOSE" == true ]] || [[ -z "${CREATED_DIRS[$dir]:-}" ]]; then
      log_info "[DRY-RUN] Would create directory: $dir"
    fi
    CREATED_DIRS[$dir]=1
  fi
  return 0
}

# Function to show file diff
show_diff() {
  local file1="$1"
  local file2="$2"

  echo -e "\n${STY_CYAN}Showing differences:${STY_RST}"
  echo -e "${STY_CYAN}Old file: $file1${STY_RST}"
  echo -e "${STY_CYAN}New file: $file2${STY_RST}"
  echo "----------------------------------------"

  if command -v diff &>/dev/null; then
    diff -u "$file1" "$file2" || true
  else
    echo "diff command not available"
  fi
  echo "----------------------------------------"
}

# Backup file before replacing
backup_file() {
  local file="$1"
  local backup_dir="${REPO_ROOT}/.update-backups"
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would backup: $file"
    return 0
  fi
  
  if [[ ! -f "$file" ]]; then
    log_warning "File does not exist, cannot backup: $file"
    return 1
  fi
  
  ensure_directory "$backup_dir" || return 1
  
  local backup_name
  local relative_name="${file#$HOME/}"
  backup_name="${relative_name//\//_}.${timestamp}.bak"
  
  if cp -p "$file" "${backup_dir}/${backup_name}" 2>/dev/null; then
    log_info "Backed up to: .update-backups/${backup_name}"
    return 0
  else
    log_error "Failed to create backup"
    return 1
  fi
}

# Function to handle file conflicts
handle_file_conflict() {
  local repo_file="$1"
  local home_file="$2"
  local filename=$(basename "$home_file")
  local dirname=$(dirname "$home_file")

  echo -e "\n${STY_YELLOW}Conflict detected:${STY_RST} $home_file"
  echo "Repository version differs from your local version."
  echo
  echo "Choose an action:"
  echo "1) Replace local file with repository version"
  echo "2) Keep local file unchanged"
  echo "3) Backup local file as ${filename}.old, use repository version"
  echo "4) Save repository version as ${filename}.new, keep local file"
  echo "5) Show diff and decide"
  echo "6) Skip this file"
  echo "7) Add to ignore and skip"
  echo "8) Backup to .update-backups/ and replace with repository version"
  echo

  while true; do
    if ! safe_read "Enter your choice (1-8): " choice "6"; then
      echo
      log_warning "Failed to read input. Skipping file."
      return
    fi

    case $choice in
    1)
      if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would replace $home_file with repository version"
      else
        cp -p "$repo_file" "$home_file"
        log_success "Replaced $home_file with repository version"
      fi
      break
      ;;
    2)
      log_info "Keeping local version of $home_file"
      break
      ;;
    3)
      if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would backup local file to ${filename}.old and update with repository version"
      else
        mv "$home_file" "${dirname}/${filename}.old"
        cp -p "$repo_file" "$home_file"
        log_success "Backed up local file to ${filename}.old and updated with repository version"
      fi
      break
      ;;
    4)
      if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would save repository version as ${filename}.new, keep local file"
      else
        cp -p "$repo_file" "${dirname}/${filename}.new"
        log_success "Saved repository version as ${filename}.new, kept local file"
      fi
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
      echo "i) Add to ignore and skip"
      echo "B) Backup to .update-backups/ and replace"

      if ! safe_read "Enter your choice (r/k/b/n/s/i/B): " subchoice "s"; then
        echo
        log_warning "Failed to read input. Skipping file."
        return
      fi

      case $subchoice in
      r)
        if [[ "$DRY_RUN" == true ]]; then
          log_info "[DRY-RUN] Would replace $home_file with repository version"
        else
          cp -p "$repo_file" "$home_file"
          log_success "Replaced $home_file with repository version"
        fi
        break
        ;;
      k)
        log_info "Keeping local version of $home_file"
        break
        ;;
      b)
        if [[ "$DRY_RUN" == true ]]; then
          log_info "[DRY-RUN] Would backup local file to ${filename}.old and update"
        else
          mv "$home_file" "${dirname}/${filename}.old"
          cp -p "$repo_file" "$home_file"
          log_success "Backed up local file to ${filename}.old and updated"
        fi
        break
        ;;
      n)
        if [[ "$DRY_RUN" == true ]]; then
          log_info "[DRY-RUN] Would save repository version as ${filename}.new"
        else
          cp -p "$repo_file" "${dirname}/${filename}.new"
          log_success "Saved repository version as ${filename}.new"
        fi
        break
        ;;
      s)
        log_info "Skipping $home_file"
        break
        ;;
      i)
        local relative_path_to_home="${home_file#$HOME/}"
        if [[ "$DRY_RUN" == true ]]; then
          log_info "[DRY-RUN] Would add '$relative_path_to_home' to $HOME_UPDATE_IGNORE_FILE"
        else
          echo "$relative_path_to_home" >>"$HOME_UPDATE_IGNORE_FILE"
          log_success "Added '$relative_path_to_home' to $HOME_UPDATE_IGNORE_FILE and skipped."
        fi
        break
        ;;
      B)
        if backup_file "$home_file"; then
          if [[ "$DRY_RUN" != true ]]; then
            cp -p "$repo_file" "$home_file"
            log_success "Replaced $home_file with repository version"
          fi
        fi
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
      if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would add '$relative_path_to_home' to $HOME_UPDATE_IGNORE_FILE"
      else
        echo "$relative_path_to_home" >>"$HOME_UPDATE_IGNORE_FILE"
        log_success "Added '$relative_path_to_home' to $HOME_UPDATE_IGNORE_FILE and skipped."
      fi
      break
      ;;
    8)
      if backup_file "$home_file"; then
        if [[ "$DRY_RUN" != true ]]; then
          cp -p "$repo_file" "$home_file"
          log_success "Replaced $home_file with repository version"
        fi
      fi
      break
      ;;
    *)
      echo "Invalid choice. Please enter 1-8."
      ;;
    esac
  done
}

# Function to check if PKGBUILD has changed
check_pkgbuild_changed() {
  local pkg_dir="$1"
  local pkgbuild_path="${pkg_dir}/PKGBUILD"

  [[ ! -f "$pkgbuild_path" ]] && return 1

  local relative_path="${pkgbuild_path#$REPO_ROOT/}"

  if [[ "$FORCE_CHECK" == true ]]; then
    return 0
  fi

  # Check if HEAD@{1} exists before trying to use it
  if ! git rev-parse --verify HEAD@{1} &>/dev/null; then
    # Fresh clone, assume all PKGBUILDs need checking
    return 0
  fi

  if git diff --name-only HEAD@{1} HEAD 2>/dev/null | grep -q "^${relative_path}$"; then
    return 0
  fi

  return 1
}

# Function to list available packages
list_packages() {
  local available_packages=()
  local changed_packages=()

  if [[ ! -d "$ARCH_PACKAGES_DIR" ]]; then
    log_warning "No package directory found"
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
    log_info "No packages found in package directory"
    return 1
  fi

  echo -e "\n${STY_CYAN}Available packages:${STY_RST}"
  for pkg in "${available_packages[@]}"; do
    if [[ " ${changed_packages[*]} " =~ " ${pkg} " ]]; then
      echo -e "  ${STY_GREEN}● ${pkg}${STY_RST} (PKGBUILD changed)"
    else
      echo -e "  ○ ${pkg}"
    fi
  done

  if [[ ${#changed_packages[@]} -gt 0 ]]; then
    echo -e "\n${STY_YELLOW}Packages with changed PKGBUILDs: ${changed_packages[*]}${STY_RST}"
  fi

  return 0
}

# Function to build selected packages
build_packages() {
  local build_mode="$1"
  local packages_to_build=()

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

  echo -e "\n${STY_CYAN}Packages to build: ${packages_to_build[*]}${STY_RST}"

  if ! safe_read "Proceed with building these packages? (Y/n): " confirm "Y"; then
    log_warning "Failed to read input. Skipping package builds."
    return
  fi

  if [[ "$confirm" =~ ^[Nn]$ ]]; then
    log_info "Package building cancelled by user"
    return
  fi
  
  for pkg_name in "${packages_to_build[@]}"; do
    pkg_dir="${ARCH_PACKAGES_DIR}/${pkg_name}"

    if [[ ! -d "$pkg_dir" || ! -f "${pkg_dir}/PKGBUILD" ]]; then
      log_error "Package not found or missing PKGBUILD: $pkg_name"
      continue
    fi

    log_info "Building package: $pkg_name"
    
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] Would build package in temp directory and clean up after"
      continue
    fi

    # Create temp build directory to avoid polluting the repo
    local build_tmp_dir
    build_tmp_dir=$(mktemp -d "/tmp/pkgbuild-${pkg_name}-XXXXXX")
    
    # Copy package files to temp directory (using /. to include hidden files)
    cp -r "$pkg_dir"/. "$build_tmp_dir/" || {
      log_error "Failed to copy package files to temp directory"
      rm -rf "$build_tmp_dir"
      continue
    }

    cd "$build_tmp_dir" || {
      log_error "Failed to change to temp build directory: $build_tmp_dir"
      rm -rf "$build_tmp_dir"
      continue
    }

    if makepkg -sCi --noconfirm; then
      log_success "Successfully built and installed $pkg_name"
      ((rebuilt_packages++)) || true
    else
      log_error "Failed to build package $pkg_name"
    fi

    # Clean up temp build directory
    cd "$REPO_ROOT" || log_die "Failed to return to repository directory"
    rm -rf "$build_tmp_dir"
    log_info "Cleaned up temp build directory"
    
    # Also clean any old build artifacts in the original package directory
    rm -rf "${pkg_dir}/src" "${pkg_dir}/pkg" "${pkg_dir}"/*.pkg.tar.* 2>/dev/null || true
  done

  if [[ $rebuilt_packages -eq 0 ]]; then
    log_warning "No packages were successfully built"
  else
    log_success "Successfully rebuilt $rebuilt_packages package(s)"
  fi
}

# Optimized function to get list of changed files
get_changed_files() {
  local dir_path="$1"

  if [[ "$FORCE_CHECK" == true ]]; then
    find "$dir_path" -type f -print0 2>/dev/null
    return
  fi
  
  # Try git-based detection first
  if git rev-parse --verify HEAD@{1} &>/dev/null 2>&1; then
    local temp_file
    temp_file=$(mktemp)
    
    # Get changed files with specific filters (Added, Copied, Modified, Renamed)
    git diff --name-only --diff-filter=ACMR HEAD@{1} HEAD 2>/dev/null | \
      while IFS= read -r file; do
        local full_path="${REPO_ROOT}/${file}"
        if [[ "$full_path" == "$dir_path"/* ]] && [[ -f "$full_path" ]]; then
          echo "$full_path"
        fi
      done > "$temp_file"
    
    if [[ -s "$temp_file" ]]; then
      # Found changes via git
      tr '\n' '\0' < "$temp_file"
      rm -f "$temp_file"
      return
    fi
    rm -f "$temp_file"
  fi
  
  # Fallback: check all files
  find "$dir_path" -type f -print0 2>/dev/null
}

# Function to check if we have new commits
has_new_commits() {
  if git rev-parse --verify HEAD@{1} &>/dev/null; then
    [[ "$(git rev-parse HEAD)" != "$(git rev-parse HEAD@{1})" ]]
  else
    # Fresh clone or no reflog - assume we want to process files
    return 0
  fi
}

# Cleanup function for signal handling
cleanup_on_exit() {
  local exit_code=$?
  
  # Remove lock file
  rm -f "${REPO_ROOT}/.update-lock" 2>/dev/null || true
  
  if [[ $exit_code -ne 0 ]] && [[ "$DRY_RUN" != true ]]; then
    echo
    log_warning "Update interrupted or failed (exit code: $exit_code)"
    log_info "System may be in an inconsistent state"
    log_info "Run the update again to complete the process"
  fi
}

# Set up signal handling and lock file
if [[ "${SOURCE_ONLY:-false}" != true ]]; then
trap cleanup_on_exit EXIT INT TERM

# Check for concurrent runs
if [[ -f "${REPO_ROOT}/.update-lock" ]]; then
  # Check if the process is still running
  if kill -0 "$(cat "${REPO_ROOT}/.update-lock" 2>/dev/null)" 2>/dev/null; then
    log_die "Another update is already running (PID: $(cat "${REPO_ROOT}/.update-lock"))"
  else
    log_warning "Found stale lock file, removing..."
    rm -f "${REPO_ROOT}/.update-lock"
  fi
fi

# Create lock file with current PID
if [[ "$DRY_RUN" != true ]]; then
  echo $$ > "${REPO_ROOT}/.update-lock"
fi

# Main script starts here
log_header "Dotfiles Update Script"

if [[ "$SKIP_NOTICE" == false ]]; then
  log_warning "THIS SCRIPT IS NOT FULLY TESTED AND MAY CAUSE ISSUES!"
  log_warning "It might be safer if you want to preserve your modifications and not delete added files,"
  log_warning "  but this can cause partial updates and therefore unexpected behavior like in #1856."
  log_warning "In general, prefer \"./setup install\" for updates if available."
  safe_read "Continue? (y/N): " response "N"

  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_error "Update aborted by user"
    exit 1
  fi
fi

# Check if we're in a git repository
cd "$REPO_ROOT" || log_die "Failed to change to repository directory"

if git rev-parse --is-inside-work-tree &>/dev/null; then
  log_info "Running in git repository: $(git rev-parse --show-toplevel)"
else
  log_error "Not in a git repository. Please run this script from your dotfiles repository."
  exit 1
fi

# Auto-detect repository structure
log_header "Detecting Repository Structure"
if detected_dirs=$(detect_repo_structure); then
  read -ra MONITOR_DIRS <<<"$detected_dirs"
  log_success "Detected repository structure:"
  for dir in "${MONITOR_DIRS[@]}"; do
    if [[ -d "${REPO_ROOT}/${dir}" ]]; then
      log_info "  ✓ ${REPO_ROOT}/${dir}"
    else
      log_warning "  ✗ ${REPO_ROOT}/${dir} (not found, will skip)"
    fi
  done
else
  log_die "Failed to detect repository structure. Make sure you're in the correct directory."
fi

# Load ignore patterns once at startup (performance optimization)
load_ignore_patterns

# Step 1: Pull latest commits
log_header "Pulling Latest Changes"

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
    log_die "Could not find main or master branch"
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
    log_die "Aborted by user"
  fi
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would stash changes"
  else
    git stash push -m "Auto-stash before update $(date)"
    log_info "Changes stashed"
  fi
fi

if git remote get-url origin &>/dev/null; then
  log_info "Pulling changes from origin/$current_branch..."
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would run: git pull --ff-only"
  else
    if git pull --ff-only; then
      log_success "Successfully pulled latest changes"
      git submodule update --init --recursive
      # Verify we actually got new commits
      if git rev-parse --verify HEAD@{1} &>/dev/null; then
        if [[ "$(git rev-parse HEAD)" == "$(git rev-parse HEAD@{1})" ]]; then
          log_info "Already up to date with remote"
        fi
      fi
    else
      log_warning "Failed to pull changes from remote."
      log_warning "This could be due to:"
      log_warning "  - Network issues"
      log_warning "  - Uncommitted local changes (use 'git stash' first)"
      log_warning "  - Diverged history (may need 'git pull --rebase')"
      log_info "Continuing with local repository state..."
    fi
  fi
else
  log_warning "No remote 'origin' configured. Skipping pull operation."
  log_info "This appears to be a local-only repository."
fi

# Step 2: Handle package building
rebuilt_packages=0

if [[ "$CHECK_PACKAGES" == true ]]; then
  log_header "Package Management"

  # Check if required Arch Linux tools are available
  if ! command -v pacman &>/dev/null || ! command -v makepkg &>/dev/null; then
    log_warning "Arch Linux package management tools (pacman/makepkg) not found."
    log_warning "Skipping package management as this appears to be a non-Arch Linux system."
    log_warning "Use -p/--packages flag only on Arch Linux systems."
    PKG_TOOLS_AVAILABLE=false
  else
    PKG_TOOLS_AVAILABLE=true
  fi

  if [[ "$PKG_TOOLS_AVAILABLE" == true ]]; then
    if [[ ! -d "$ARCH_PACKAGES_DIR" ]]; then
      log_warning "No packages directory found (tried: dist-arch, arch-packages, sdata/dist-arch)."
      log_warning "Skipping package management."
    else
      # Scan for changed PKGBUILDs
      changed_pkgbuilds=()
      for pkg_dir in "$ARCH_PACKAGES_DIR"/*/; do
        if [[ -f "${pkg_dir}/PKGBUILD" ]]; then
          pkg_name=$(basename "$pkg_dir")
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

        if [[ "$NON_INTERACTIVE" == true ]]; then
          pkg_choice="1"
          log_info "Non-interactive mode: Using default package option: $pkg_choice"
        elif safe_read "Choose an option (1-4): " pkg_choice "1"; then
          if [[ "$VERBOSE" == true ]]; then
            log_info "User selected package option: $pkg_choice"
          fi
        else
          log_warning "Failed to read input. Skipping package building."
          pkg_choice=""
        fi

        if [[ -n "$pkg_choice" ]]; then
          case $pkg_choice in
            1) build_packages "changed" ;;
            2)
              if list_packages; then
                build_packages "select"
              fi
              ;;
            3) build_packages "all" ;;
            4|*) log_info "Skipping package building" ;;
          esac
        fi
      else
        log_info "No PKGBUILDs have changed since last update."
        echo
        if [[ "$NON_INTERACTIVE" == true ]]; then
          check_anyway="N"
          log_info "Non-interactive mode: Using default for check packages anyway: $check_anyway"
        elif safe_read "Do you want to check and build packages anyway? (y/N): " check_anyway "N"; then
          if [[ "$VERBOSE" == true ]]; then
            log_info "User chose to check packages anyway: $check_anyway"
          fi
        else
          log_warning "Failed to read input. Skipping package management."
          check_anyway=""
        fi

        if [[ -n "$check_anyway" && "$check_anyway" =~ ^[Yy]$ ]]; then
          if list_packages; then
            echo
            echo "Package build options:"
            echo "1) Select specific packages to build"
            echo "2) Build all packages"
            echo "3) Skip package building"

            if safe_read "Choose an option (1-3): " build_choice "3"; then
              case $build_choice in
                1) build_packages "select" ;;
                2) build_packages "all" ;;
                3|*) log_info "Skipping package building" ;;
              esac
            else
              log_info "Skipping package building"
            fi
          fi
        else
          log_info "Skipping package management"
        fi
      fi
    fi
  fi
else
  log_header "Package Management"
  log_info "Package checking disabled. Use -p or --packages flag to enable package management."
fi

# Step 3: Update configuration files
log_header "Updating Configuration Files"

process_files=false
if [[ "$FORCE_CHECK" == true ]]; then
  process_files=true
  log_info "Force mode: checking all configuration files"
elif has_new_commits; then
  process_files=true
  log_info "New commits detected: checking changed configuration files"
else
  log_info "No new commits found and force mode not enabled: skipping file updates"
  process_files=false
fi

if [[ "$process_files" == true ]]; then
  files_processed=0
  files_updated=0
  files_created=0
  
  # Count total files for progress indication (optional)
  total_files=0
  if [[ "$VERBOSE" == false ]] && command -v tput &>/dev/null 2>&1; then
    for dir_name in "${MONITOR_DIRS[@]}"; do
      repo_dir_path="${REPO_ROOT}/${dir_name}"
      [[ ! -d "$repo_dir_path" ]] && continue
      total_files=$((total_files + $(find "$repo_dir_path" -type f 2>/dev/null | wc -l)))
    done
  fi

  for dir_name in "${MONITOR_DIRS[@]}"; do
    repo_dir_path="${REPO_ROOT}/${dir_name}"
    
    if [[ ! -d "$repo_dir_path" ]]; then
      if [[ "$VERBOSE" == true ]]; then
        log_warning "Skipping non-existent directory: $repo_dir_path"
      fi
      continue
    fi
    
    # FIX: Properly handle dots/ prefix mapping
    if [[ "$dir_name" == dots/* ]]; then
      # Strip "dots/" prefix for home directory mapping
      home_subdir="${dir_name#dots/}"
      home_dir_path="${HOME}/${home_subdir}"
    else
      # Direct structure
      home_dir_path="${HOME}/${dir_name}"
    fi

    log_info "Processing directory: $dir_name → ${home_dir_path}"

    ensure_directory "$home_dir_path" || continue

    while IFS= read -r -d '' repo_file; do
      # Calculate relative path from the repo source directory
      rel_path="${repo_file#$repo_dir_path/}"
      home_file="${home_dir_path}/${rel_path}"

      if should_ignore "$home_file"; then
        if [[ "$VERBOSE" == true ]]; then
          log_info "Ignored: $rel_path (matches ignore pattern)"
        fi
        continue
      fi

      if [[ "$VERBOSE" == true ]]; then
        log_info "Processing: $rel_path"
      fi

      ((files_processed++))
      
      # Show progress for non-verbose mode
      if [[ "$VERBOSE" == false ]] && command -v tput &>/dev/null 2>&1 && [[ $total_files -gt 0 ]]; then
        printf "\r[INFO] Processing files: %d/%d" "$files_processed" "$total_files" >&2
      fi

      ensure_directory "$(dirname "$home_file")" || continue

      if [[ -f "$home_file" ]]; then
        if ! cmp -s "$repo_file" "$home_file"; then
          # Clear progress line if showing
          if [[ "$VERBOSE" == false ]] && command -v tput &>/dev/null 2>&1 && [[ $total_files -gt 0 ]]; then
            printf "\r%*s\r" "80" "" >&2
          fi
          
          log_info "Found difference in: $rel_path"
          if [[ "$DRY_RUN" == true ]]; then
            log_warning "[DRY-RUN] Conflict detected (would prompt): $home_file"
            ((files_updated++))
          else
            handle_file_conflict "$repo_file" "$home_file"
            ((files_updated++))
          fi
        fi
      else
        if [[ "$DRY_RUN" == true ]]; then
          if [[ "$VERBOSE" == true ]]; then
            log_info "[DRY-RUN] Would create new file: $home_file"
          fi
        else
          cp -p "$repo_file" "$home_file"
          if [[ "$VERBOSE" == true ]]; then
            log_success "Created new file: $home_file"
          fi
        fi
        ((files_created++))
      fi
    done < <(get_changed_files "$repo_dir_path") || true
    echo
  done

  # Clear progress line if it was shown
  if [[ "$VERBOSE" == false ]] && command -v tput &>/dev/null 2>&1 && [[ $total_files -gt 0 ]]; then
    printf "\r%*s\r" "80" "" >&2
  fi

  echo
  log_info "File processing summary:"
  log_info "- Files processed: $files_processed"
  log_info "- Files with conflicts: $files_updated"
  log_info "- New files created: $files_created"
else
  log_info "Skipping file updates (no changes detected and not in force mode)"
fi

# Step 4: Update script permissions
log_header "Updating Script Permissions"

if [[ -d "${HOME}/.local/bin" ]]; then
  if [[ "$DRY_RUN" == true ]]; then
    log_info "[DRY-RUN] Would update script permissions in ~/.local/bin"
  else
    find "${HOME}/.local/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
    log_success "Updated ~/.local/bin script permissions"
  fi
fi

log_header "Update Complete"
if [[ "$DRY_RUN" == true ]]; then
  log_warning "DRY-RUN MODE: No changes were actually made"
  log_info "Run without -n/--dry-run to apply changes"
else
  log_success "Dotfiles update completed successfully!"
fi

echo
echo -e "${STY_CYAN}Summary:${STY_RST}"
if command -v git >/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  echo "- Repository: $(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null || echo 'Unknown')"
else
  echo "- Repository: Unknown (git not available)"
fi
echo "- Branch: ${current_branch:-Unknown}"
echo "- Structure: ${MONITOR_DIRS[*]}"
echo "- Mode: $([ "$FORCE_CHECK" == true ] && echo "Force check" || echo "Normal")"
echo "- Package checking: $([ "$CHECK_PACKAGES" == true ] && echo "Enabled" || echo "Disabled")"

if [[ $rebuilt_packages -gt 0 ]]; then
  echo "- Packages rebuilt: $rebuilt_packages"
fi

if [[ "$process_files" == true ]]; then
  echo "- Files processed: $files_processed"
  echo "- Files updated/conflicted: $files_updated"
  echo "- New files created: $files_created"
fi

if [[ ! -f "$HOME_UPDATE_IGNORE_FILE" && ! -f "$UPDATE_IGNORE_FILE" ]]; then
  echo
  log_info "Tip: Create ignore files to exclude files from updates:"
  echo "  - Repository ignore: ${REPO_ROOT}/.updateignore"
  echo "  - User ignore: ~/.updateignore"
  echo
  echo "Example patterns:"
  echo "  *.log                 # Ignore all .log files"
  echo "  .config/personal/     # Ignore entire directory"
  echo "  secret-config.conf    # Ignore specific file"
  echo "  /temp-file            # Ignore from root only"
  echo "  **secret**            # Ignore files containing 'secret'"
fi

# Show backup directory if any backups were created
if [[ -d "${REPO_ROOT}/.update-backups" ]] && [[ "$DRY_RUN" != true ]]; then
  echo
  log_info "Backups stored in: ${REPO_ROOT}/.update-backups/"
fi

fi

echo
