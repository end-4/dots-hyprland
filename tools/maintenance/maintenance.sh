#!/usr/bin/env bash
#
# Auto-desktopenv Maintenance Script
# Daily/weekly system maintenance automation
#
# Features:
#   - System update
#   - Package cache cleanup
#   - Orphan removal
#   - Journal cleanup
#   - Disk space report
#   - SMART health check
#   - Service health check
#
# Usage:
#   maintenance.sh [OPTIONS]
#
# Options:
#   --dry-run    Show what would be done
#   --auto       Run without prompts
#   --help       Show help
#

set -euo pipefail
source "$(dirname "$(realpath "$0")")/../../tools/lib/common.sh"





DRY_RUN=false
AUTO_MODE=false


usage() {
    cat << 'EOF'
maintenance.sh - System maintenance automation

USAGE:
    maintenance.sh [OPTIONS]

OPTIONS:
    --dry-run    Show what would be done without making changes
    --auto       Run without prompts
    --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --auto) AUTO_MODE=true; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if [[ $EUID -eq 0 ]]; then
    log_error "Do not run as root. Run as normal user with sudo available."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    log_error "sudo is required but not found."
    exit 1
fi

echo ""
log_info "========================================"
log_info " System Maintenance"
log_info "========================================"
echo ""

# 1. System update
log_info "1. Checking for system updates..."
if command -v pacman >/dev/null 2>&1; then
    if $DRY_RUN; then
        log_info "[DRY-RUN] Would run: sudo pacman -Syu"
    else
        sudo pacman -Syu --noconfirm
    fi
    log_success "System updated"
else
    log_warning "Not an Arch-based system, skipping system update"
fi

# 2. Clean package cache
log_info "2. Cleaning package cache..."
if command -v pacman >/dev/null 2>&1; then
    if $DRY_RUN; then
        log_info "[DRY-RUN] Would run: sudo pacman -Sc --noconfirm"
    else
        sudo pacman -Sc --noconfirm || true
    fi
    log_success "Package cache cleaned"
fi

if command -v yay >/dev/null 2>&1; then
    if $DRY_RUN; then
        log_info "[DRY-RUN] Would run: yay -Sc --noconfirm"
    else
        yay -Sc --noconfirm || true
    fi
    log_success "AUR cache cleaned"
fi

# 3. Remove orphans
log_info "3. Removing orphan packages..."
if command -v pacman >/dev/null 2>&1; then
    orphans=$(pacman -Qtdq 2>/dev/null || true)
    if [[ -n "$orphans" ]]; then
        if $DRY_RUN; then
            log_info "[DRY-RUN] Would remove orphans: $(echo "$orphans" | wc -l) packages"
        else
            echo "$orphans" | sudo pacman -Rns --noconfirm - || true
        fi
        log_success "Orphans removed"
    else
        log_info "No orphans found"
    fi
fi

# 4. Clean journal
log_info "4. Cleaning system journal..."
if command -v journalctl >/dev/null 2>&1; then
    if $DRY_RUN; then
        log_info "[DRY-RUN] Would run: sudo journalctl --vacuum-time=7d"
    else
        sudo journalctl --vacuum-time=7d || true
    fi
    log_success "Journal cleaned"
fi

# 5. Disk space report
log_info "5. Disk space report:"
df -h /home | awk 'NR==1 {print} NR==2 {print "  Home: "$4" available"}'

# 6. SMART health check
log_info "6. Checking disk health..."
if command -v smartctl >/dev/null 2>&1; then
    disk=$(df /home | awk 'NR==2 {print $1}' | sed 's/[0-9]//g')
    if [[ -n "$disk" ]]; then
        sudo smartctl -H "$disk" 2>/dev/null | grep -E "PASSED|FAILED|SMART" || log_warning "SMART check not available"
    fi
else
    log_warning "smartctl not installed, skipping disk health check"
fi

# 7. Service health check
log_info "7. Checking critical services..."
services=(bluetooth NetworkManager systemd-timesyncd)
for svc in "${services[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        log_success "$svc is running"
    else
        log_warning "$svc is not running"
    fi
done

# 8. Memory usage
log_info "8. Memory usage:"
free -h | awk 'NR==1 {print} NR==2 {print "  RAM: "$3" / "$2" used"}'

# 9. Temperature (if available)
log_info "9. Temperature:"
if command -v sensors >/dev/null 2>&1; then
    sensors 2>/dev/null | grep -E "Core|Package|temp1" | head -5 || log_warning "Temperature sensors not available"
else
    log_warning "lm_sensors not installed"
fi

echo ""
log_success "Maintenance completed"
log_info "Run with --auto for non-interactive mode"
echo ""
