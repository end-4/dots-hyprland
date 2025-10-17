#!/usr/bin/env bash
#
# update.sh - Enhanced dotfiles update script
#
# Features:
# - Auto-detect repository structure (dots/ prefix or direct config)
# - Pull latest commits from remote
# - Rebuild packages if PKGBUILD files changed (user choice)
# - Handle config file conflicts with user choices
# - Respect .updateignore file for exclusions
#
set -euo pipefail

# === Configuration ===
FORCE_CHECK=false
CHECK_PACKAGES=false
DRY_RUN=false
VERBOSE=false
REPO_DIR="$(cd "$(dirname "$(dirname "$(dirname "$0")")")" &>/dev/null && pwd)"
# Try to find the packages directory (different names in different versions)
if [[ -d "${REPO_DIR}/dist-arch" ]]; then
  ARCH_PACKAGES_DIR="${REPO_DIR}/dist-arch"
elif [[ -d "${REPO_DIR}/arch-packages" ]]; then
  ARCH_PACKAGES_DIR="${REPO_DIR}/arch-packages"
elif [[ -d "${REPO_DIR}/sdist/arch" ]]; then
  ARCH_PACKAGES_DIR="${REPO_DIR}/sdist/arch"
else
  ARCH_PACKAGES_DIR="${REPO_DIR}/dist-arch"  # Default fallback
fi
UPDATE_IGNORE_FILE="${REPO_DIR}/.updateignore"
HOME_UPDATE_IGNORE_FILE="${HOME}/.updateignore"

# Auto-detect repository structure
detect_repo_structure() {
  local found_dirs=()
  
  # Check for dots/ prefixed structure
  if [[ -d "${REPO_DIR}/dots/.config" ]]; then
    found_dirs+=("dots/.config")
    [[ -d "${REPO_DIR}/dots/.local/bin" ]] && found_dirs+=("dots/.local/bin")
    [[ -d "${REPO_DIR}/dots/.local/share" ]] && found_dirs+=("dots/.local/share")
  # Check for flat structure
  elif [[ -d "${REPO_DIR}/.config" ]]; then
    found_dirs+=(".config")
    [[ -d "${REPO_DIR}/.local/bin" ]] && found_dirs+=(".local/bin")
    [[ -d "${REPO_DIR}/.local/share" ]] && found_dirs+=(".local/share")
  else
    # Manual detection of common directories
    for candidate in "dots/.config" ".config" "config" "dots/.local/bin" ".local/bin" "dots/.local/share" ".local/share"; do
      if [[ -d "${REPO_DIR}/${candidate}" ]]; then
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

  local input_value=""

  echo -n "$prompt"
  if { read -r input_value </dev/tty; } 2>/dev/null || read -r input_value 2>/dev/null; then
    # Use printf instead of eval for security
    printf -v "$varname" '%s' "$input_value"
    return 0
  else
    if [[ -n "$default" ]]; then
      echo
      log_warning "Using default: $default"
      printf -v "$varname" '%s' "$default"
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
          # Check parent directories against pattern
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

# Function to show file diff
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

      if ! safe_read "Enter your choice (r/k/b/n/s/i): " subchoice "s"; then
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

  local relative_path="${pkgbuild_path#$REPO_DIR/}"

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
  local build_mode="$1"
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
    pkg_dir="${ARCH_PACKAGES_DIR}/${pkg_name}"

    if [[ ! -d "$pkg_dir" || ! -f "${pkg_dir}/PKGBUILD" ]]; then
      log_error "Package not found or missing PKGBUILD: $pkg_name"
      continue
    fi

    log_info "Building package: $pkg_name"
    
    if [[ "$DRY_RUN" == true ]]; then
      log_info "[DRY-RUN] Would build package in directory: $pkg_dir"
      continue
    fi

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

# Function to get list of changed files
get_changed_files() {
  local dir_path="$1"

  if [[ "$FORCE_CHECK" == true ]]; then
    find "$dir_path" -type f -print0 2>/dev/null
  else
    # Check if we can use git diff (HEAD@{1} exists)
    if git rev-parse --verify HEAD@{1} &>/dev/null; then
      # Get files that changed in the last pull
      local has_changes=false
      while IFS= read -r file; do
        local full_path="${REPO_DIR}/${file}"
        if [[ "$full_path" == "$dir_path"/* ]] && [[ -f "$full_path" ]]; then
          printf '%s\0' "$full_path"
          has_changes=true
        fi
      done < <(git diff --name-only HEAD@{1} HEAD 2>/dev/null || true)
      
      # If git diff found changes, we're done
      if [[ "$has_changes" == true ]]; then
        return
      fi
    fi
    
    # Fallback: check all files (fresh clone or no git changes)
    find "$dir_path" -type f -print0 2>/dev/null
  fi
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
  -n | --dry-run)
    DRY_RUN=true
    log_info "Dry-run mode enabled - no changes will be made"
    shift
    ;;
  -v | --verbose)
    VERBOSE=true
    log_info "Verbose mode enabled"
    shift
    ;;
  -h | --help)
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --force      Force check all files even if no new commits"
    echo "  -p, --packages   Enable package checking and building"
    echo "  -n, --dry-run    Show what would be done without making changes"
    echo "  -v, --verbose    Enable verbose output"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "This script updates your dotfiles by:"
    echo "  1. Auto-detecting repository structure (dots/ prefix or direct)"
    echo "  2. Pulling latest changes from git remote"
    echo "  3. Optionally rebuilding packages (if -p flag is used)"
    echo "  4. Syncing configuration files to home directory"
    echo "  5. Updating script permissions"
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
  log_warning "In general, prefer install.sh for updates if available."
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

# Auto-detect repository structure
log_header "Detecting Repository Structure"
if detected_dirs=$(detect_repo_structure); then
  read -ra MONITOR_DIRS <<<"$detected_dirs"
  log_success "Detected repository structure:"
  for dir in "${MONITOR_DIRS[@]}"; do
    if [[ -d "${REPO_DIR}/${dir}" ]]; then
      log_info "  ✓ ${REPO_DIR}/${dir}"
    else
      log_warning "  ✗ ${REPO_DIR}/${dir} (not found, will skip)"
    fi
  done
else
  die "Failed to detect repository structure. Make sure you're in the correct directory."
fi

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
    else
      log_warning "Failed to pull changes from remote. Continuing with local repository..."
      log_info "You may need to resolve conflicts manually later."
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

  if [[ ! -d "$ARCH_PACKAGES_DIR" ]]; then
    log_warning "No packages directory found (tried: dist-arch, arch-packages, sdist/arch). Skipping package management."
  else
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

      if safe_read "Choose an option (1-4): " pkg_choice "1"; then
        case $pkg_choice in
        1) build_packages "changed" ;;
        2)
          if list_packages; then
            build_packages "select"
          fi
          ;;
        3) build_packages "all" ;;
        4 | *) log_info "Skipping package building" ;;
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
              1) build_packages "select" ;;
              2) build_packages "all" ;;
              3 | *) log_info "Skipping package building" ;;
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

process_files=false
if [[ "$FORCE_CHECK" == true ]]; then
  process_files=true
  log_info "Force mode: checking all configuration files"
elif has_new_commits; then
  process_files=true
  log_info "New commits detected: checking changed configuration files"
else
  log_info "No new commits found: checking for local file differences"
  process_files=true
fi

if [[ "$process_files" == true ]]; then
  files_processed=0
  files_updated=0
  files_created=0

  for dir_name in "${MONITOR_DIRS[@]}"; do
    repo_dir_path="${REPO_DIR}/${dir_name}"
    
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

    if [[ "$DRY_RUN" != true ]]; then
      mkdir -p "$home_dir_path"
    else
      log_info "[DRY-RUN] Would create directory: $home_dir_path"
    fi

    while IFS= read -r -d '' repo_file; do
      # Calculate relative path from the repo source directory
      rel_path="${repo_file#$repo_dir_path/}"
      home_file="${home_dir_path}/${rel_path}"

      if should_ignore "$home_file"; then
        continue
      fi

      ((files_processed++))

      if [[ "$DRY_RUN" != true ]]; then
        mkdir -p "$(dirname "$home_file")"
      fi

      if [[ -f "$home_file" ]]; then
        if ! cmp -s "$repo_file" "$home_file"; then
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
          log_info "[DRY-RUN] Would create new file: $home_file"
        else
          cp -p "$repo_file" "$home_file"
          log_success "Created new file: $home_file"
        fi
        ((files_created++))
      fi
    done < <(get_changed_files "$repo_dir_path") || true
  done

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
echo -e "${CYAN}Summary:${NC}"
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
