#!/usr/bin/env bash
source "$(dirname "$(realpath "$0")")/../lib/common.sh"

function tune_bore_scheduler() {
  if [[ -f /sys/kernel/debug/sched/burst_penalty_scale ]]; then
    echo 1280 | sudo tee /sys/kernel/debug/sched/burst_penalty_scale > /dev/null
    log_success "BORE burst_penalty_scale set to 1280"
  fi
}

function tune_vm_parameters() {
  echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-vm-tune.conf > /dev/null
  echo "vm.dirty_ratio=5" | sudo tee -a /etc/sysctl.d/99-vm-tune.conf > /dev/null
  echo "vm.dirty_background_ratio=2" | sudo tee -a /etc/sysctl.d/99-vm-tune.conf > /dev/null
  sudo sysctl --system > /dev/null
  log_success "VM parameters tuned for 32GB RAM + NVMe SSD"
}

function tune_network() {
  echo "net.core.default_qdisc=cake" | sudo tee /etc/sysctl.d/99-network.conf > /dev/null
  echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/99-network.conf > /dev/null
  sudo sysctl --system > /dev/null
  log_success "Network tuned: CAKE + BBR"
}

function tune_audio() {
  if command_exists pipewire; then
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/pipewire/pipewire.conf.d/"
    cat > "${XDG_CONFIG_HOME:-$HOME/.config}/pipewire/pipewire.conf.d/10-latency.conf" <<'EOC'
context.properties = {
  default.clock.rate = 48000
  default.clock.quantum = 64
  default.clock.min-quantum = 32
  default.clock.max-quantum = 512
}
EOC
    systemctl --user restart pipewire.service pipewire-pulse.service || true
    log_success "PipeWire low-latency config applied"
  fi
}

tune_bore_scheduler
tune_vm_parameters
tune_network
tune_audio
