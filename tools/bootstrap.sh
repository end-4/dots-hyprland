#!/usr/bin/env bash
#
# Auto-desktopenv Online Bootstrap
# One-command installer for MSI Sword 16 HX B14VEKG
#
# Usage:
#   bash <(curl -s https://raw.githubusercontent.com/gaganjainse/Auto-desktopenv/main/tools/bootstrap.sh)
#
# Or manually:
#   curl -s https://raw.githubusercontent.com/gaganjainse/Auto-desktopenv/main/tools/bootstrap.sh | bash
#
set -euo pipefail
source "$(dirname "$(realpath "$0")")/lib/common.sh"

SKIP_AI=false
SKIP_NVIDIA=false
SKIP_ZRAM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-ai) SKIP_AI=true; shift;;
    --skip-nvidia) SKIP_NVIDIA=true; shift;;
    --skip-zram) SKIP_ZRAM=true; shift;;
    *) shift;;
  esac
done

export SKIP_AI SKIP_NVIDIA SKIP_ZRAM






preflight() {
    echo ""
    log_info "========================================"
    log_info " Auto-desktopenv Online Bootstrap"
    log_info " MSI Sword 16 HX B14VEKG"
    log_info "========================================"
    echo ""

    if [[ $EUID -eq 0 ]]; then
        log_error "Do NOT run this as root. Run as normal user with sudo available."
        exit 1
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        log_error "sudo is required but not found. Install it first."
        exit 1
    fi

    if ! ping -c 1 archlinux.org >/dev/null 2>&1; then
        log_error "No network connectivity. Check WiFi/Ethernet."
        exit 1
    fi
    log_success "Network reachable"

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        log_info "OS: ${NAME:-Unknown} ${VERSION:-}"
        if [[ "${ID:-}" != "cachyos" && "${ID:-}" != "arch" ]]; then
            log_warning "This script is designed for CachyOS/Arch. You are on ${ID}."
            read -p "Continue anyway? [y/N] " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
        fi
    fi

    INSTALL_USER="$(whoami)"
    log_info "Target user: ${INSTALL_USER}"

    local available
    available=$(df -h /home | awk 'NR==2 {print $4}')
    log_info "Home partition available: ${available}"
}

install_prerequisites() {
    log_info "=== Installing Prerequisites ==="

    log_info "Updating system..."
    sudo pacman -Syu --noconfirm

    log_info "Installing prerequisites..."
    sudo pacman -S --noconfirm --needed \
        git curl wget base-devel yay \
        inotify-tools python python-pip go rustup

    log_success "Prerequisites installed"
}

clone_repo() {
    log_info "=== Cloning Repository ==="

    local repo_url="https://github.com/gaganjainse/Auto-desktopenv.git"
    local install_dir="${HOME}/Workspace/Auto-desktopenv"

    mkdir -p "${HOME}/Workspace"

    if [[ -d "${install_dir}/.git" ]]; then
        log_info "Repository already exists, pulling latest..."
        cd "${install_dir}"
        git pull --ff-only || true
    else
        log_info "Cloning repository..."
        git clone "${repo_url}" "${install_dir}"
    fi

    log_success "Repository ready at ${install_dir}"
}

run_installer() {
    log_info "=== Running Main Installer ==="

    local install_dir="${HOME}/Workspace/Auto-desktopenv"

    if [[ ! -f "${install_dir}/setup" ]]; then
        log_error "Installer not found at ${install_dir}/setup"
        exit 1
    fi

    log_info "Starting full installation..."
    log_info "  - System update"
    log_info "  - NVIDIA drivers + hybrid graphics"
    log_info "  - dots-hyprland (illogical-impulse fork)"
    log_info "  - MSI MUX switcher"
    log_info "  - Smart Organizer"
    log_info "  - Power management + utilities"
    log_info "  - Final verification"
    echo ""

    read -p "Continue? [Y/n] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0

    cd "${install_dir}"
    ./setup install
}

main() {
    preflight
    install_prerequisites
    clone_repo
    run_installer

    echo ""
    log_success "========================================"
    log_success " Bootstrap Complete"
    log_success "========================================"
    log_info "Reboot and select Hyprland at login."
    log_info "After reboot:"
    log_info "  - Test MUX: sudo msi-mux-switcher status"
    log_info "  - Test modes: sudo msi-mux-switcher hybrid|dgpu|igpu"
    log_info "  - Test AI: ollama run qwen2.5:7b"
    log_info "  - Test GPU: prime-run glxinfo | grep NVIDIA"
    log_info "  - Test organizer: smart-organizer --dry-run"
    log_info "  - Check organizer service: systemctl --user status smart-organizer"
    echo ""
}

main "$@"
