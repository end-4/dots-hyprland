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
REPO_DIR="$(cd "$(dirname $0)" &>/dev/null && pwd)"
ARCH_PACKAGES_DIR="${REPO_DIR}/arch-packages"
UPDATE_IGNORE_FILE="${REPO_DIR}/.updateignore"
HOME_UPDATE_IGNORE_FILE="${HOME}/.updateignore"

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

# Function to install Python packages using uv
install_python_packages() {
  local python_pkgs_dir="${REPO_DIR}/scriptdata/python-packages"
  
  if [[ ! -f "$python_pkgs_dir" ]]; then
    log_warning "Python packages file not found: $python_pkgs_dir"
    return 1
  fi

  log_info "Installing Python packages using uv..."
  
  # Source the python packages installation function
  if [[ -f "${REPO_DIR}/scriptdata/installers" ]]; then
    source "${REPO_DIR}/scriptdata/installers"
    install-python-packages
    log_success "Python packages installed successfully"
  else
    log_error "Could not find installers script"
    return 1
  fi
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
  echo "7) Add to ignore and skip"
  echo

  while true; do
    if ! safe_read "Enter your choice (1-7): " choice "6"; then
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
      echo "i) Add to ignore and skip"

      if ! safe_read "Enter your choice (r/k/b/n/s/i): " subchoice "s"; then
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
      i)
        local relative_path_to_home="${home_file#$HOME/}"
        echo "$relative_path_to_home" >>"$HOME_UPDATE_IGNORE_FILE"
        log_success "Added '$relative_path_to_home' to $HOME_UPDATE_IGNORE_FILE and skipped."
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
      echo "$relative_path_to_home" >>"$HOME_UPDATE_IGNORE_FILE"
      log_success "Added '$relative_path_to_home' to $HOME_UPDATE_IGNORE_FILE and skipped."
      break
      ;;
    *)
      echo "Invalid choice. Please enter 1-7."
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
  for pkg in "${available_packages[@]}"; do
    if [[ " ${changed_packages[*]} " =~ " ${pkg} " ]]; then
      echo -e "  ${GREEN}● ${pkg}${NC} (PKGBUILD changed)"
    else
      echo -e "  ○ ${pkg}"
    fi
  done

  if [[ ${#changed_packages[@]} -gt 0 ]]; then
    echo -e "\n${YELLOW}Packages with changed PKGBUILDs: ${changed_packages[*]}${NC}"
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
  -h | --help)
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --force      Force check all files even if no new commits"
    echo "  -p, --packages   Enable package checking and building"
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
  log_warning "It might be safer if you want to preserve your modifications and not delete added files,"
  log_warning "  but this can cause partial updates and therefore unexpected behavior like in #1856."
  log_warning "In general, prefer install.sh for updates."
  safe_read "Continue? (y/N): " response "N"

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

# Source required files for configuration handling
if [[ -f "${REPO_DIR}/scriptdata/environment-variables" ]]; then
  source "${REPO_DIR}/scriptdata/environment-variables"
fi

if [[ -f "${REPO_DIR}/scriptdata/functions" ]]; then
  source "${REPO_DIR}/scriptdata/functions"
fi

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

  # Handle MISC configs (everything except fish and hypr)
  log_info "Processing miscellaneous configuration files..."
  for i in $(find .config/ -mindepth 1 -maxdepth 1 ! -name 'fish' ! -name 'hypr' -exec basename {} \;); do
    config_path=".config/$i"
    target_path="$XDG_CONFIG_HOME/$i"
    
    if should_ignore "$target_path"; then
      continue
    fi
    
    echo "[$0]: Found target: $config_path"
    if [[ -d "$config_path" ]]; then
      if [[ -d "$target_path" ]]; then
        # Directory exists, handle conflicts file by file
        find "$config_path" -type f | while read -r file; do
          rel_path="${file#$config_path/}"
          target_file="$target_path/$rel_path"
          
          if should_ignore "$target_file"; then
            continue
          fi
          
          mkdir -p "$(dirname "$target_file")"
          
          if [[ -f "$target_file" ]] && ! cmp -s "$file" "$target_file"; then
            handle_file_conflict "$file" "$target_file"
            ((files_updated++))
          elif [[ ! -f "$target_file" ]]; then
            cp -p "$file" "$target_file"
            log_success "Created new file: $target_file"
            ((files_created++))
          fi
          ((files_processed++))
        done
      else
        # Directory doesn't exist, create it
        mkdir -p "$target_path"
        rsync -av "$config_path/" "$target_path/"
        log_success "Created new directory: $target_path"
        ((files_created++))
      fi
    elif [[ -f "$config_path" ]]; then
      mkdir -p "$(dirname "$target_path")"
      if [[ -f "$target_path" ]] && ! cmp -s "$config_path" "$target_path"; then
        handle_file_conflict "$config_path" "$target_path"
        ((files_updated++))
      elif [[ ! -f "$target_path" ]]; then
        cp -p "$config_path" "$target_path"
        log_success "Created new file: $target_path"
        ((files_created++))
      fi
      ((files_processed++))
    fi
  done

  # Handle Fish configuration
  log_info "Processing Fish configuration..."
  fish_source=".config/fish"
  fish_target="$XDG_CONFIG_HOME/fish"
  
  if [[ -d "$fish_source" ]]; then
    if [[ -d "$fish_target" ]]; then
      # Handle fish config with conflict resolution
      find "$fish_source" -type f | while read -r file; do
        rel_path="${file#$fish_source/}"
        target_file="$fish_target/$rel_path"
        
        if should_ignore "$target_file"; then
          continue
        fi
        
        mkdir -p "$(dirname "$target_file")"
        
        if [[ -f "$target_file" ]] && ! cmp -s "$file" "$target_file"; then
          handle_file_conflict "$file" "$target_file"
          ((files_updated++))
        elif [[ ! -f "$target_file" ]]; then
          cp -p "$file" "$target_file"
          log_success "Created new fish config file: $target_file"
          ((files_created++))
        fi
        ((files_processed++))
      done
    else
      mkdir -p "$fish_target"
      rsync -av "$fish_source/" "$fish_target/"
      log_success "Created Fish configuration directory"
      ((files_created++))
    fi
  fi

  # Handle Hyprland configuration with special logic
  log_info "Processing Hyprland configuration..."
  hypr_source=".config/hypr"
  hypr_target="$XDG_CONFIG_HOME/hypr"
  
  if [[ -d "$hypr_source" ]]; then
    mkdir -p "$hypr_target"
    
    # Handle all files except the special ones
    find "$hypr_source" -type f ! -path "*/custom/*" ! -name "hyprland.conf" ! -name "hypridle.conf" ! -name "hyprlock.conf" | while read -r file; do
      rel_path="${file#$hypr_source/}"
      target_file="$hypr_target/$rel_path"
      
      if should_ignore "$target_file"; then
        continue
      fi
      
      mkdir -p "$(dirname "$target_file")"
      
      if [[ -f "$target_file" ]] && ! cmp -s "$file" "$target_file"; then
        handle_file_conflict "$file" "$target_file"
        ((files_updated++))
      elif [[ ! -f "$target_file" ]]; then
        cp -p "$file" "$target_file"
        log_success "Created new Hyprland config file: $target_file"
        ((files_created++))
      fi
      ((files_processed++))
    done
    
    # Handle special Hyprland config files
    for config_file in "hyprland.conf" "hypridle.conf" "hyprlock.conf"; do
      source_file="$hypr_source/$config_file"
      target_file="$hypr_target/$config_file"
      
      if [[ -f "$source_file" ]]; then
        if [[ -f "$target_file" ]]; then
          if ! cmp -s "$source_file" "$target_file"; then
            echo -e "\n${YELLOW}Special Hyprland config detected: $config_file${NC}"
            echo "This is a critical Hyprland configuration file."
            handle_file_conflict "$source_file" "$target_file"
            ((files_updated++))
          fi
        else
          cp -p "$source_file" "$target_file"
          log_success "Created new Hyprland config: $target_file"
          ((files_created++))
        fi
        ((files_processed++))
      fi
    done
    
    # Handle custom directory (never overwrite)
    custom_source="$hypr_source/custom"
    custom_target="$hypr_target/custom"
    
    if [[ -d "$custom_source" && ! -d "$custom_target" ]]; then
      rsync -av "$custom_source/" "$custom_target/"
      log_success "Created Hyprland custom directory"
      ((files_created++))
    elif [[ -d "$custom_source" && -d "$custom_target" ]]; then
      log_info "Hyprland custom directory exists, skipping (preserved user customizations)"
    fi
  fi

  # Process the original monitored directories for any remaining files
  for dir_name in "${MONITOR_DIRS[@]}"; do
    repo_dir_path="${REPO_DIR}/${dir_name}"
    home_dir_path="${HOME}/${dir_name}"

    if [[ ! -d "$repo_dir_path" ]]; then
      continue
    fi

    # Only process files not already handled above
    if [[ "$dir_name" != ".config" ]]; then
      log_info "Processing directory: $dir_name"
      mkdir -p "$home_dir_path"

      while IFS= read -r -d '' repo_file; do
        rel_path="${repo_file#$repo_dir_path/}"
        home_file="${home_dir_path}/${rel_path}"

        if should_ignore "$home_file"; then
          continue
        fi

        ((files_processed++))
        mkdir -p "$(dirname "$home_file")"

        if [[ -f "$home_file" ]]; then
          if ! cmp -s "$repo_file" "$home_file"; then
            log_info "Found difference in: $rel_path"
            handle_file_conflict "$repo_file" "$home_file"
            ((files_updated++))
          fi
        else
          cp -p "$repo_file" "$home_file"
          log_success "Created new file: $home_file"
          ((files_created++))
        fi
      done < <(get_changed_files "$repo_dir_path")
    fi
  done

  # Show processing summary
  echo
  log_info "File processing summary:"
  log_info "- Files processed: $files_processed"
  log_info "- Files with conflicts: $files_updated"
  log_info "- New files created: $files_created"
else
  log_info "Skipping file updates (no changes detected and not in force mode)"
fi

# Step 3.5: Update system services and settings
log_header "Updating System Services and Settings"

# Install Python packages if they exist
if [[ -f "${REPO_DIR}/scriptdata/python-packages" ]]; then
  if safe_read "Update Python packages? (Y/n): " update_python "Y"; then
    if [[ ! "$update_python" =~ ^[Nn]$ ]]; then
      install_python_packages
    fi
  fi
fi

# Update system settings (only if force mode or user confirms)
update_system_settings=false
if [[ "$FORCE_CHECK" == true ]]; then
  update_system_settings=true
elif safe_read "Update system settings (font, theme, etc.)? (y/N): " update_settings "N"; then
  if [[ "$update_settings" =~ ^[Yy]$ ]]; then
    update_system_settings=true
  fi
fi

if [[ "$update_system_settings" == true ]]; then
  log_info "Updating system settings..."
  
  # Update user groups
  if ! groups $(whoami) | grep -q video; then
    log_info "Adding user to video group..."
    sudo usermod -aG video "$(whoami)"
  fi
  
  if ! groups $(whoami) | grep -q i2c; then
    log_info "Adding user to i2c group..."
    sudo usermod -aG i2c "$(whoami)"
  fi
  
  if ! groups $(whoami) | grep -q input; then
    log_info "Adding user to input group..."
    sudo usermod -aG input "$(whoami)"
  fi
  
  # Update module loading
  if [[ ! -f /etc/modules-load.d/i2c-dev.conf ]]; then
    log_info "Setting up i2c-dev module loading..."
    echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
  fi
  
  # Update services
  log_info "Enabling and starting services..."
  systemctl --user enable ydotool --now 2>/dev/null || log_warning "Could not enable ydotool service"
  sudo systemctl enable bluetooth --now 2>/dev/null || log_warning "Could not enable bluetooth service"
  
  # Update GNOME settings
  log_info "Updating GNOME settings..."
  gsettings set org.gnome.desktop.interface font-name 'Rubik 11' 2>/dev/null || log_warning "Could not set GNOME font"
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || log_warning "Could not set GNOME color scheme"
  
  # Update KDE settings
  log_info "Updating KDE settings..."
  kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly 2>/dev/null || log_warning "Could not set KDE widget style"
  
  log_success "System settings updated"
else
  log_info "Skipping system settings update"
fi

# Reload Hyprland if running
if pgrep -x "Hyprland" > /dev/null; then
  log_info "Reloading Hyprland configuration..."
  sleep 1
  hyprctl reload 2>/dev/null && log_success "Hyprland reloaded" || log_warning "Could not reload Hyprland"
fi

# Step 4: Update script permissions
log_header "Update Complete"
log_success "Dotfiles update completed successfully!"

# Show summary
echo
echo -e "${CYAN}Summary:${NC}"
echo "- Repository: $(git log -1 --pretty=format:'%h - %s (%cr)')"
echo "- Branch: $current_branch"
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

echo "- Configuration directories: ${MONITOR_DIRS[*]}"

# Post-installation reminders
echo
echo -e "${CYAN}Post-update reminders:${NC}"
echo "- Check https://end-4.github.io/dots-hyprland-wiki/en/i-i/01setup/#post-installation"
echo "- Press Ctrl+Super+T to select a wallpaper"  
echo "- Press Super+/ for a list of keybinds"

# Environment variable warning
if [[ -z "${ILLOGICAL_IMPULSE_VIRTUAL_ENV}" ]]; then
  echo
  echo -e "${YELLOW}Warning: ILLOGICAL_IMPULSE_VIRTUAL_ENV environment variable is not set.${NC}"
  echo -e "${YELLOW}Please ensure it's set to ~/.local/state/quickshell/.venv or Quickshell won't work.${NC}"
  echo -e "${YELLOW}Check ~/.config/hypr/hyprland/env.conf and restart Hyprland.${NC}"
fi

# Remind about ignore files if none exist
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
