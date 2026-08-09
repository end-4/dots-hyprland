#!/usr/bin/env bash
#
# smart-organizer - Systemwide intelligent file organizer
# Part of Auto-desktopenv / dots-hyprland fork
#
# Features:
#   - Systemwide file classification and organization
#   - Folder operations: create, move, merge, split, delete
#   - Cache/trash/bloat cleanup
#   - Heuristic-based decision making
#   - Dry-run mode for safety
#
# Usage:
#   smart-organizer.sh [OPTIONS] [TARGETS...]
#
# Options:
#   --dry-run          Show what would be done without making changes
#   --once             Run once and exit
#   --watch            Continuously watch for changes
#   --clean            Run cleanup mode (cache, trash, bloat)
#   --organize         Run organization mode (sort files into folders)
#   --folders          Run folder operations (merge, split, dedupe)
#   --all              Run all modes (default)
#   --help             Show this help
#
# Targets (default: ~/Downloads ~/Documents ~/Pictures ~/Videos ~/Music ~/Desktop):
#   Paths to organize. Use "system" for systemwide cleanup.
#
# Examples:
#   smart-organizer.sh --dry-run
#   smart-organizer.sh --clean system
#   smart-organizer.sh --organize ~/Downloads
#   smart-organizer.sh --folders ~/Documents
#   smart-organizer.sh --watch
#

set -euo pipefail
source "$(dirname "$(realpath "$0")")/../lib/common.sh"





# =============================================================================
# Configuration
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_REAL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
LIB_DIR="${SCRIPT_REAL_DIR}/lib"

# Load user configuration if it exists
USER_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/smart-organizer/smart-organizer.conf"
if [[ -f "$USER_CONFIG" ]]; then
    source "$USER_CONFIG"
fi

# Default targets
DEFAULT_TARGETS=(
    "$HOME/Downloads"
    "$HOME/Documents"
    "$HOME/Pictures"
    "$HOME/Videos"
    "$HOME/Music"
    "$HOME/Desktop"
)

# Systemwide cleanup targets
SYSTEM_CACHE_DIRS=(
    "$HOME/.cache"
    "$HOME/.config"
    "$HOME/.local/share"
)

# Trash locations
TRASH_DIRS=(
    "$HOME/.local/share/Trash"
    "$HOME/.trash"
    "$HOME/.cache/trash"
)

# Age thresholds (in days)
CACHE_MAX_AGE=30
TRASH_MAX_AGE=30
OLD_INSTALLER_MAX_AGE=90
TEMP_MAX_AGE=7
DOWNLOADS_PROMOTION_AGE=30
OLD_MEDIA_AGE=180
BUILD_ARTIFACT_MAX_AGE=30

# File size thresholds (in MB)
LARGE_FILE_THRESHOLD_MB=1024
DUPLICATE_CHECK_SIZE=10

# Lock file for mutual exclusion (kernel-managed via flock)
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/smart-organizer.lock"

# Protected patterns (never touch these)
PROTECTED_PATTERNS=(
    "*.ssh"
    "*.gnupg"
    "*.key"
    "*.pem"
    "*.secret"
    "*.password"
    "*backup*"
    "*password*"
    "*credentials*"
    ".git"
    ".svn"
)

# =============================================================================
# Colors and logging
# =============================================================================
log_action() { echo -e "${CYAN}[ACT]${NC}   $*"; }

# =============================================================================
# Safety and dry-run
# =============================================================================
DRY_RUN=false
LOG_FILE="/tmp/smart-organizer-$(date +%Y%m%d-%H%M%S).log"

is_dry_run() {
    [[ "$DRY_RUN" == "true" ]]
}

log_action_dry() {
    if is_dry_run; then
        log_action "[DRY-RUN] $*"
    else
        log_action "$*"
    fi
}

# =============================================================================
# Load libraries
# =============================================================================
source "${LIB_DIR}/report.sh"
source "${LIB_DIR}/config.sh"
source "${LIB_DIR}/content.sh"
source "${LIB_DIR}/safety.sh"
source "${LIB_DIR}/heuristics.sh"
source "${LIB_DIR}/cleanup.sh"
source "${LIB_DIR}/organize.sh"
source "${LIB_DIR}/media.sh"
source "${LIB_DIR}/downloads.sh"
source "${LIB_DIR}/folders.sh"

# =============================================================================
# Help
# =============================================================================
show_help() {
    cat << 'EOF'
smart-organizer - Systemwide intelligent file organizer

USAGE:
    smart-organizer.sh [OPTIONS] [TARGETS...]

OPTIONS:
    --dry-run          Show what would be done without making changes
    --once             Run once and exit
    --watch            Continuously watch for changes
    --clean            Run cleanup mode (cache, trash, bloat)
    --organize         Run organization mode (sort files into folders)
    --folders          Run folder operations (merge, split, dedupe)
    --exempt PATH      Add path to exempt from organization
    --recovery         List items in recovery directory
    --restore NAME     Restore item from recovery directory
    --purge-recovery   Permanently delete all items in recovery
    --all              Run all modes (default)
    --help             Show this help

TARGETS:
    Paths to organize. Default: ~/Downloads ~/Documents ~/Pictures ~/Videos ~/Music ~/Desktop
    Use "system" for systemwide cleanup.

EXAMPLES:
    smart-organizer.sh --dry-run
    smart-organizer.sh --clean system
    smart-organizer.sh --organize ~/Downloads
    smart-organizer.sh --folders ~/Documents
    smart-organizer.sh --watch
EOF
}

# =============================================================================
# Main
# =============================================================================
main() {
    local mode="all"
    local targets=()
    local watch_mode=false
    local ONCE_MODE=false
    local RESTORE_NAME=""

    # Acquire kernel-managed lock to prevent overlapping runs from timer/service/manual.
    # Unlike pidfiles, flock is automatically released by the kernel if this process
    # crashes, is SIGKILL'd, or loses power — no stale lock can accumulate.
    if ! exec 200>"$LOCK_FILE"; then
        log_error "Cannot open lock file: $LOCK_FILE"
        exit 1
    fi
    if ! flock -n 200; then
        log_warning "Another instance is already running. Exiting."
        exit 0
    fi

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --once)
                ONCE_MODE=true
                shift
                ;;
            --watch)
                watch_mode=true
                shift
                ;;
            --clean)
                mode="clean"
                shift
                ;;
            --organize)
                mode="organize"
                shift
                ;;
            --folders)
                mode="folders"
                shift
                ;;
            --dedupe-hardlink)
                mode="dedupe-hardlink"
                shift
                ;;
            --exempt)
                shift
                add_exempt_path "$1"
                shift
                ;;
            --recovery)
                mode="recovery"
                shift
                ;;
            --restore)
                mode="restore"
                shift
                RESTORE_NAME="$1"
                shift
                ;;
            --purge-recovery)
                mode="purge-recovery"
                shift
                ;;
            --all)
                mode="all"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                targets+=("$1")
                shift
                ;;
        esac
    done

    # Set default targets if none provided
    if [[ ${#targets[@]} -eq 0 ]]; then
        targets=("${DEFAULT_TARGETS[@]}")
    fi

    # Banner
    echo ""
    log_info "========================================"
    log_info " Smart Organizer"
    log_info " Mode: ${mode}"
    log_info " Dry-run: ${DRY_RUN}"
    log_info " Targets: ${targets[*]}"
    log_info "========================================"
    echo ""

    # Safety check
    if ! safety_check; then
        log_error "Safety check failed. Aborting."
        exit 1
    fi

    # Run selected mode(s)
    case $mode in
        clean)
            run_cleanup "${targets[@]}"
            ;;
        organize)
            run_organize "${targets[@]}"
            if [[ ${#targets[@]} -eq 0 ]]; then
                promote_downloads
            fi
            ;;
        folders)
            run_folder_ops "${targets[@]}"
            ;;
        dedupe-hardlink)
            dedupe_hardlink "${targets[@]}"
            ;;
        recovery)
            list_recovery
            ;;
        restore)
            if [[ -z "$RESTORE_NAME" ]]; then
                log_error "Please specify the item to restore: --restore <name>"
                exit 1
            fi
            restore_from_recovery "$RESTORE_NAME"
            ;;
        purge-recovery)
            purge_recovery
            ;;
        all)
            run_cleanup "${targets[@]}"
            run_organize "${targets[@]}"
            if [[ ${#targets[@]} -eq 0 ]]; then
                promote_downloads
            fi
            run_folder_ops "${targets[@]}"
            dedupe_hardlink "${targets[@]}"
            ;;
    esac

    if [[ "$ONCE_MODE" == true ]]; then
        echo ""
        log_success "Smart Organizer completed (once)."
        log_info "Log saved to: ${LOG_FILE}"
        print_report
        echo ""
        exit 0
    fi

    if [[ "$watch_mode" == true ]]; then
        echo ""
        log_info "Watching for new files... Press Ctrl+C to stop."
        
        while true; do
            run_cleanup "${targets[@]}"
            run_organize "${targets[@]}"
            run_folder_ops "${targets[@]}"
            sleep 300
        done
    fi

    echo ""
    log_success "Smart Organizer completed."
    log_info "Log saved to: ${LOG_FILE}"
    print_report
    echo ""
}

main "$@"
# CI trigger test
