#!/usr/bin/env bash
# Custom updater script for illogical-impulse dotfiles
# Place this file in dots/custom/ and it will be sourced by the setup script
# You can also run it directly: bash dots/custom/updater.sh

# This script forcefully updates configuration files by:
# 1. Backing up existing configs (optional)
# 2. Removing existing config files/dirs that exist in the repo
# 3. Copying fresh configs from the repo

showhelp(){
cat << 'EOF'
Custom Updater Script for illogical-impulse

This script forcefully updates configuration files.
Custom additions in ~/.config/hypr/custom will be preserved.

WARNING: This will overwrite your existing configs!

Syntax:
  ./custom/updater.sh [OPTIONS...]

Options:
  -h, --help          Show this help message
  -y, --yes           Auto-confirm all prompts (dangerous)
  -n, --dry-run       Show what would be done without doing it
  --skip-backup       Skip backup of existing configs
  --only-quickshell   Only update quickshell configs
  --only-hyprland     Only update hyprland configs
  --only-hypr         Only update hyprland configs (alias)
  --no-reload         Don't reload hyprland/quickshell after update

Examples:
  ./custom/updater.sh                  # Interactive mode with backup
  ./custom/updater.sh -y               # Auto-confirm, backup and update
  ./custom/updater.sh -y --skip-backup # Auto-confirm, no backup
  ./custom/updater.sh --only-quickshell -y

EOF
}

# Detect repo root
cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"

# Source library functions
if [[ -f "sdata/lib/environment-variables.sh" ]]; then
  source sdata/lib/environment-variables.sh
fi
if [[ -f "sdata/lib/functions.sh" ]]; then
  source sdata/lib/functions.sh
fi

# Default values
AUTO_CONFIRM=false
DRY_RUN=false
SKIP_BACKUP=false
ONLY_QUICKSHELL=false
ONLY_HYPRLAND=false
NO_RELOAD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      showhelp
      exit 0
      ;;
    -y|--yes)
      AUTO_CONFIRM=true
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    --skip-backup)
      SKIP_BACKUP=true
      shift
      ;;
    --only-quickshell)
      ONLY_QUICKSHELL=true
      shift
      ;;
    --only-hyprland|--only-hypr)
      ONLY_HYPRLAND=true
      shift
      ;;
    --no-reload)
      NO_RELOAD=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      showhelp
      exit 1
      ;;
  esac
done

# Colors (if lib not loaded)
if [[ -z "$STY_CYAN" ]]; then
  STY_CYAN='\033[0;36m'
  STY_GREEN='\033[0;32m'
  STY_YELLOW='\033[0;33m'
  STY_RED='\033[0;31m'
  STY_RST='\033[0m'
fi

# Set XDG defaults if not loaded
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
BACKUP_DIR="${HOME}/ii-original-dots-backup"

# Dry run mode
if [[ "$DRY_RUN" == true ]]; then
  echo -e "${STY_CYAN}[DRY RUN] Would perform the following actions:${STY_RST}"
fi

# Confirmation prompt
if [[ "$AUTO_CONFIRM" != true ]]; then
  echo -e "${STY_YELLOW}WARNING: This script will overwrite existing configs!${STY_RST}"
  if [[ "$SKIP_BACKUP" == true ]]; then
    echo -e "${STY_RED}BACKUP IS DISABLED!${STY_RST}"
  fi
  echo ""
  read -p "Are you sure you want to continue? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Function to backup a file/directory
backup_item() {
  local src="$1"
  local backup_dir="${BACKUP_DIR}/$(date +%Y%m%d_%H%M%S)"

  if [[ "$SKIP_BACKUP" == true ]]; then
    return 0
  fi

  if [[ -e "$src" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
      echo -e "${STY_CYAN}[DRY RUN] Would backup: $src -> ${backup_dir}/$(basename "$src")${STY_RST}"
    else
      mkdir -p "$backup_dir"
      cp -r "$src" "${backup_dir}/"
      echo -e "${STY_GREEN}Backed up: $src${STY_RST}"
    fi
  fi
}

# Function to remove and replace a config file
update_file() {
  local src="$1"
  local dest="$2"

  if [[ ! -f "$src" ]]; then
    echo -e "${STY_YELLOW}Source file does not exist: $src${STY_RST}"
    return 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${STY_CYAN}[DRY RUN] Would update: $dest${STY_RST}"
  else
    backup_item "$dest"
    mkdir -p "$(dirname "$dest")"
    rm -f "$dest"
    cp -f "$src" "$dest"
    echo -e "${STY_GREEN}Updated: $dest${STY_RST}"
  fi
}

# Function to remove and replace a config directory
update_dir() {
  local src="$1"
  local dest="$2"
  shift 2
  local exclude_patterns=("$@")

  if [[ ! -d "$src" ]]; then
    echo -e "${STY_YELLOW}Source directory does not exist: $src${STY_RST}"
    return 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${STY_CYAN}[DRY RUN] Would update directory: $dest${STY_RST}"
  else
    backup_item "$dest"

    if [[ -d "$dest" ]]; then
      # Remove existing directory
      rm -rf "$dest"
    fi

    mkdir -p "$(dirname "$dest")"

    if [[ ${#exclude_patterns[@]} -gt 0 ]]; then
      # Copy with excludes using rsync
      local exclude_args=()
      for pattern in "${exclude_patterns[@]}"; do
        exclude_args+=(--exclude "$pattern")
      done
      rsync -a "${exclude_args[@]}" "$src/" "$dest/"
    else
      # Simple copy
      cp -r "$src" "$dest"
    fi
    echo -e "${STY_GREEN}Updated: $dest${STY_RST}"
  fi
}

echo -e "${STY_CYAN}Starting custom force update...${STY_RST}"
echo -e "${STY_CYAN}Repo root: $REPO_ROOT${STY_RST}"
echo ""

# Update Quickshell configs
if [[ "$ONLY_QUICKSHELL" == true ]] || [[ "$ONLY_HYPRLAND" == false ]]; then
  echo -e "${STY_CYAN}Updating Quickshell configs...${STY_RST}"
  update_dir "${REPO_ROOT}/dots/.config/quickshell" "$XDG_CONFIG_HOME/quickshell"
fi

# Update Hyprland configs
if [[ "$ONLY_HYPRLAND" == true ]] || [[ "$ONLY_QUICKSHELL" == false ]]; then
  echo -e "${STY_CYAN}Updating Hyprland configs...${STY_RST}"

  # Main hyprland config (sync)
  update_dir "${REPO_ROOT}/dots/.config/hypr/hyprland" "$XDG_CONFIG_HOME/hypr/hyprland"

  # Individual config files
  for file in hypr{land,lock}.conf {monitors,workspaces}.conf; do
    if [[ -f "${REPO_ROOT}/dots/.config/hypr/$file" ]]; then
      update_file "${REPO_ROOT}/dots/.config/hypr/$file" "$XDG_CONFIG_HOME/hypr/$file"
    fi
  done

  # Hypridle config
  if [[ -f "${REPO_ROOT}/dots/.config/hypr/hypridle.conf" ]]; then
    update_file "${REPO_ROOT}/dots/.config/hypr/hypridle.conf" "$XDG_CONFIG_HOME/hypr/hypridle.conf"
  fi

  # Custom directory (preserve .local files)
  if [[ -d "${REPO_ROOT}/dots/.config/hypr/custom" ]]; then
    update_dir "${REPO_ROOT}/dots/.config/hypr/custom" "$XDG_CONFIG_HOME/hypr/custom" "*.local" "*.backup" "*.bak"
  fi
fi

# Update other configs (only if not doing partial update)
if [[ "$ONLY_QUICKSHELL" == false ]] && [[ "$ONLY_HYPRLAND" == false ]]; then
  echo -e "${STY_CYAN}Updating other configs...${STY_RST}"

  # Misc configs (excluding quickshell, fish, hypr, fontconfig)
  for item in "${REPO_ROOT}/dots/.config/"*/; do
    local name=$(basename "$item")
    if [[ "$name" != "quickshell" ]] && [[ "$name" != "fish" ]] && [[ "$name" != "hypr" ]] && [[ "$name" != "fontconfig" ]]; then
      update_dir "$item" "$XDG_CONFIG_HOME/$name"
    fi
  done

  # Fish config
  if [[ -d "${REPO_ROOT}/dots/.config/fish" ]]; then
    update_dir "${REPO_ROOT}/dots/.config/fish" "$XDG_CONFIG_HOME/fish" "conf.d"
  fi

  # Fontconfig
  if [[ -d "${REPO_ROOT}/dots/.config/fontconfig" ]]; then
    update_dir "${REPO_ROOT}/dots/.config/fontconfig" "$XDG_CONFIG_HOME/fontconfig"
  fi

  # Local share files
  if [[ -d "${REPO_ROOT}/dots/.local/share/konsole" ]]; then
    update_dir "${REPO_ROOT}/dots/.local/share/konsole" "$XDG_DATA_HOME/konsole"
  fi

  # Icon
  if [[ -f "${REPO_ROOT}/dots/.local/share/icons/illogical-impulse.svg" ]]; then
    update_file "${REPO_ROOT}/dots/.local/share/icons/illogical-impulse.svg" "$XDG_DATA_HOME/icons/illogical-impulse.svg"
  fi
fi

# Reload
if [[ "$NO_RELOAD" == false ]] && [[ "$DRY_RUN" == false ]]; then
  echo ""
  echo -e "${STY_CYAN}Reloading Hyprland...${STY_RST}"
  sleep 1
  if command -v hyprctl &> /dev/null; then
    hyprctl reload 2>/dev/null || echo "Note: hyprctl reload failed (may not be running)"
  fi

  echo ""
  echo -e "${STY_CYAN}Quickshell configs updated.${STY_RST}"
  echo -e "${STY_CYAN}Quickshell should auto-reload, or you can run:${STY_RST}"
  echo "  pkill qs; qs -c ii"
fi

echo ""
echo -e "${STY_GREEN}Update complete!${STY_RST}"
if [[ "$SKIP_BACKUP" == false ]] && [[ "$DRY_RUN" == false ]]; then
  echo -e "${STY_CYAN}Backups saved to: ${BACKUP_DIR}${STY_RST}"
fi
