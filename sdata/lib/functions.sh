# This is NOT a script for execution, but for loading functions, so NOT need execution permission or shebang.
# NOTE that you NOT need to `cd ..' because the `$0' is NOT this file, but the script file which will source this file.

# shellcheck shell=bash

function try { "$@" || sleep 0; }
function v(){
  echo -e "####################################################"
  echo -e "${STY_BLUE}[$0]: Next command:${STY_RST}"
  echo -e "${STY_GREEN}$*${STY_RST}"
  local execute=true
  if $ask;then
    while true;do
      echo -e "${STY_BLUE}Execute? ${STY_RST}"
      echo "  y = Yes"
      echo "  e = Exit now"
      echo "  s = Skip this command (NOT recommended - your setup might not work correctly)"
      echo "  yesforall = Yes and don't ask again; NOT recommended unless you really sure"
      local p; read -p "====> " p
      case $p in
        [yY]) echo -e "${STY_BLUE}OK, executing...${STY_RST}" ;break ;;
        [eE]) echo -e "${STY_BLUE}Exiting...${STY_RST}" ;exit ;break ;;
        [sS]) echo -e "${STY_BLUE}Alright, skipping this one...${STY_RST}" ;execute=false ;break ;;
        "yesforall") echo -e "${STY_BLUE}Alright, won't ask again. Executing...${STY_RST}"; ask=false ;break ;;
        *) echo -e "${STY_RED}Please enter [y/e/s/yesforall].${STY_RST}";;
      esac
    done
  fi
  if $execute;then x "$@";else
    echo -e "${STY_YELLOW}[$0]: Skipped \"$*\"${STY_RST}"
  fi
}
# When use v() for a defined function, use x() INSIDE its definition to catch errors.
function x(){
  if "$@";then local cmdstatus=0;else local cmdstatus=1;fi # 0=normal; 1=failed; 2=failed but ignored
  while [ $cmdstatus == 1 ] ;do
    echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$*${STY_RED}\" has failed."
    echo -e "You may need to resolve the problem manually BEFORE repeating this command."
    echo -e "[Tip] If a certain package is failing to install, try installing it separately in another terminal.${STY_RST}"
    echo "  r = Repeat this command (DEFAULT)"
    echo "  e = Exit now"
    echo "  i = Ignore this error and continue (your setup might not work correctly)"
    local p; read -p " [R/e/i]: " p
    case $p in
      [iI]) echo -e "${STY_BLUE}Alright, ignore and continue...${STY_RST}";cmdstatus=2;;
      [eE]) echo -e "${STY_BLUE}Alright, will exit.${STY_RST}";break;;
      *) echo -e "${STY_BLUE}OK, repeating...${STY_RST}"
         if "$@";then cmdstatus=0;else cmdstatus=1;fi
         ;;
    esac
  done
  case $cmdstatus in
    0) echo -e "${STY_BLUE}[$0]: Command \"${STY_GREEN}$*${STY_BLUE}\" finished.${STY_RST}";;
    1) echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$*${STY_RED}\" has failed. Exiting...${STY_RST}";exit 1;;
    2) echo -e "${STY_RED}[$0]: Command \"${STY_GREEN}$*${STY_RED}\" has failed but ignored by user.${STY_RST}";;
  esac
}
function showfun(){
  echo -e "${STY_BLUE}[$0]: The definition of function \"$1\" is as follows:${STY_RST}"
  printf "${STY_GREEN}"
  type -a "$1" 2>/dev/null || return 1
  printf "${STY_RST}"
}
function pause(){
  if [ ! "$ask" == "false" ];then
    printf "${STY_FAINT}${STY_SLANT}"
    local p; read -p "(Ctrl-C to abort, others to proceed)" p
    printf "${STY_RST}"
  fi
}
function remove_bashcomments_emptylines(){
  mkdir -p "$(dirname "$2")" && cat "$1" | sed -e 's/#.*//' -e '/^[[:space:]]*$/d' > "$2"
}
function prevent_sudo_or_root(){
  case $(whoami) in
    root) echo -e "${STY_RED}[$0]: This script is NOT to be executed with sudo or as root. Aborting...${STY_RST}";exit 1;;
  esac
}
function git_auto_unshallow(){
# We need this function for latest_commit_hash to work properly
  if [[ -f "$(git rev-parse --git-dir)/shallow" ]]; then
    echo "Shallow clone detected. Unshallowing..."
    git fetch --unshallow
  fi
}
function latest_commit_timestamp(){
  local target_path="$1"
  local result=$(git log -1 --format="%ct" -- "$target_path" 2>/dev/null)
  if [[ -z "$result" ]]; then
    echo "[latest_commit_timestamp] The timestamp of \"$target_path\" is empty. Aborting..." >&2
    return 1
  fi
  echo "$result"
}

function log_info() {
  echo -e "${STY_BLUE}[INFO]${STY_RST} $1"
}
function log_success() {
  echo -e "${STY_GREEN}[SUCCESS]${STY_RST} $1"
}
function log_warning() {
  echo -e "${STY_YELLOW}[WARNING]${STY_RST} $1"
}
function log_error() {
  echo -e "${STY_RED}[ERROR]${STY_RST} $1" >&2
}
function log_header() {
  echo -e "\n${STY_PURPLE}=== $1 ===${STY_RST}"
}
function log_die() {
  log_error "$1"
  exit 1
}

# Enhanced: Check if command exists
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Enhanced: Require a command or die
function require_command() {
  if ! command_exists "$1"; then
    log_die "Required command '$1' not found. Please install it first."
  fi
}

# Enhanced: Sanitize file paths to prevent directory traversal
function sanitize_path() {
  local path="$1"
  
  # Remove null bytes, newlines, and control characters
  path=$(echo "$path" | tr -d '\000-\037')
  
  # Prevent directory traversal beyond current context
  case "$path" in
    ..|../*|*/../*|*/..|\.\./*)
      log_die "Invalid path detected (directory traversal attempt): $path"
      ;;
  esac
  
  echo "$path"
}

# Enhanced: Safe file comparison that checks existence first
function files_differ() {
  local file1="$1"
  local file2="$2"
  
  # Check if both files exist
  if [[ ! -f "$file1" ]] || [[ ! -f "$file2" ]]; then
    return 0  # Consider them different if either doesn't exist
  fi
  
  # Quick size check first (faster than byte comparison)
  local size1 size2
  if command -v stat &>/dev/null; then
    # Try both BSD and GNU stat formats
    size1=$(stat -f%z "$file1" 2>/dev/null || stat -c%s "$file1" 2>/dev/null)
    size2=$(stat -f%z "$file2" 2>/dev/null || stat -c%s "$file2" 2>/dev/null)
    
    if [[ "$size1" != "$size2" ]]; then
      return 0  # Different sizes = different files
    fi
  fi
  
  # Then byte-by-byte comparison
  cmp -s "$file1" "$file2" && return 1 || return 0
}

# Enhanced: Create backup of a file with timestamp
function backup_file_simple() {
  local file="$1"
  local backup_suffix="${2:-.bak}"
  
  if [[ ! -f "$file" ]]; then
    log_warning "Cannot backup non-existent file: $file"
    return 1
  fi
  
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  local backup_name="${file}${backup_suffix}.${timestamp}"
  
  if cp -p "$file" "$backup_name" 2>/dev/null; then
    log_info "Backed up: $file → $backup_name"
    return 0
  else
    log_error "Failed to backup: $file"
    return 1
  fi
}

# Enhanced: Validate that a file path is within allowed directory
function validate_path_in_directory() {
  local file_path="$1"
  local allowed_dir="$2"
  
  # Resolve to absolute paths
  local abs_file
  local abs_dir
  
  abs_file=$(cd "$(dirname "$file_path")" 2>/dev/null && pwd -P)/$(basename "$file_path") || return 1
  abs_dir=$(cd "$allowed_dir" 2>/dev/null && pwd -P) || return 1
  
  # Check if file path starts with allowed directory
  case "$abs_file" in
    "$abs_dir"/*)
      return 0
      ;;
    *)
      log_error "Path validation failed: $file_path is not within $allowed_dir"
      return 1
      ;;
  esac
}

# Enhanced: Check if script is running in a CI/CD environment
function is_ci_environment() {
  [[ -n "${CI:-}" ]] || \
  [[ -n "${GITHUB_ACTIONS:-}" ]] || \
  [[ -n "${GITLAB_CI:-}" ]] || \
  [[ -n "${TRAVIS:-}" ]] || \
  [[ -n "${CIRCLECI:-}" ]]
}

# Enhanced: Progress bar (optional, for long operations)
function show_progress() {
  local current="$1"
  local total="$2"
  local message="${3:-Processing}"
  
  if ! command_exists tput; then
    return
  fi
  
  local percent=$((current * 100 / total))
  local bar_length=40
  local filled=$((bar_length * current / total))
  local empty=$((bar_length - filled))
  
  printf "\r${message}: [" >&2
  printf "%${filled}s" | tr ' ' '=' >&2
  printf "%${empty}s" | tr ' ' ' ' >&2
  printf "] %d%%" "$percent" >&2
  
  if [[ $current -eq $total ]]; then
    echo >&2
  fi
}


# Enhanced: Cleanup temporary files on exit
#declare -a TEMP_FILES_TO_CLEANUP=()
function register_temp_file() {
  local temp_file="$1"
  TEMP_FILES_TO_CLEANUP+=("$temp_file")
}

function cleanup_temp_files() {
  for temp_file in "${TEMP_FILES_TO_CLEANUP[@]}"; do
    if [[ -f "$temp_file" ]]; then
      rm -f "$temp_file" 2>/dev/null || true
    fi
  done
  TEMP_FILES_TO_CLEANUP=()
}

# Enhanced: Check disk space before operations
function check_disk_space() {
  local path="${1:-.}"
  local required_mb="${2:-100}"  # Default 100MB
  
  if ! command_exists df; then
    log_warning "df command not available, skipping disk space check"
    return 0
  fi
  
  local available_kb
  available_kb=$(df -k "$path" | awk 'NR==2 {print $4}')
  local available_mb=$((available_kb / 1024))
  
  if [[ $available_mb -lt $required_mb ]]; then
    log_warning "Low disk space: ${available_mb}MB available, ${required_mb}MB recommended"
    return 1
  fi
  
  return 0
}
