#!/usr/bin/env bash

function undo_nvidia_mux() {
  log_info "Undoing NVIDIA mkinitcpio changes..."
  if [[ -f /etc/mkinitcpio.conf ]]; then
    v sudo sed -i 's/i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm //' /etc/mkinitcpio.conf
    if command_exists limine-mkinitcpio; then
      v sudo limine-mkinitcpio || true
    else
      v sudo mkinitcpio -P || true
    fi
  fi

  v sudo rm -f /etc/udev/rules.d/igpu-device-path.rules
  v sudo rm -f /etc/udev/rules.d/dgpu-device-path.rules
  v sudo udevadm control --reload-rules || true

  log_warning "Bootloader kernel params NOT automatically removed. Manually remove nvidia_drm.modeset=1 from your bootloader."
}

function undo_ai_stack() {
  log_info "Stopping and disabling Ollama..."
  v sudo systemctl disable --now ollama.service || true
  v sudo pacman -Rns --noconfirm ollama || true
  local venv="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv"
  v rm -rf "$venv"
  log_success "AI stack removed"
}

function undo_smart_organizer() {
  v systemctl --user disable --now smart-organizer.service smart-organizer.timer || true
  v rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/smart-organizer."{service,timer}
  v systemctl --user daemon-reload || true
}

function undo_backup() {
  v systemctl --user disable --now backup.timer backup.service || true
  v rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/backup."{service,timer}
  v systemctl --user daemon-reload || true
}

function undo_power_management() {
  v sudo systemctl disable --now systemd-zram-setup@zram0.service || true
  v sudo rm -f /etc/systemd/zram-generator.conf
  v sudo systemctl disable --now power-profiles-daemon.service || true
}

undo_nvidia_mux
undo_ai_stack
undo_smart_organizer
undo_backup
undo_power_management
