#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
REPO_ROOT="$(pwd)"
source ./sdata/lib/environment-variables.sh
source ./sdata/lib/functions.sh

prevent_sudo_or_root
set -e



BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

printf "${STY_CYAN}[$0]: Smart Organizer Setup${STY_RST}\n"
pause

# Install smart-organizer
SMART_ORGANIZER_DIR="${REPO_ROOT}/tools/smart-organizer"
SMART_ORGANIZER_BIN="${BIN_DIR}/smart-organizer"

if [[ ! -d "$SMART_ORGANIZER_DIR" ]]; then
    die "smart-organizer directory not found at $SMART_ORGANIZER_DIR"
fi

# Create symlink to bin
v mkdir -p "$BIN_DIR"
v ln -sf "${SMART_ORGANIZER_DIR}/smart-organizer.sh" "$SMART_ORGANIZER_BIN"
v chmod +x "$SMART_ORGANIZER_BIN"

# Install backup/maintenance symlinks if present
BACKUP_DIR="${REPO_ROOT}/tools/backup"
MAINTENANCE_DIR="${REPO_ROOT}/tools/maintenance"
if [[ -f "${BACKUP_DIR}/backup.sh" ]]; then
  v ln -sf "${BACKUP_DIR}/backup.sh" "${BIN_DIR}/backup.sh"
  v chmod +x "${BIN_DIR}/backup.sh"
fi
if [[ -f "${MAINTENANCE_DIR}/maintenance.sh" ]]; then
  v ln -sf "${MAINTENANCE_DIR}/maintenance.sh" "${BIN_DIR}/maintenance.sh"
  v chmod +x "${BIN_DIR}/maintenance.sh"
fi

# Install default configuration
v mkdir -p "${CONFIG_DIR}/smart-organizer"
if [[ ! -f "${CONFIG_DIR}/smart-organizer/smart-organizer.conf" ]]; then
  v cp "${SMART_ORGANIZER_DIR}/smart-organizer.conf" "${CONFIG_DIR}/smart-organizer/smart-organizer.conf"
fi

# Install systemd user service for watch mode
v mkdir -p "${CONFIG_DIR}/systemd/user"

cat > "${CONFIG_DIR}/systemd/user/smart-organizer.service" << EOFSERVICE
[Unit]
Description=Smart Organizer Watch Service
After=network.target

[Service]
Type=simple
ExecStart=${BIN_DIR}/smart-organizer --watch
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOFSERVICE

# Install systemd user timer for periodic runs
cat > "${CONFIG_DIR}/systemd/user/smart-organizer-timer.service" << EOFSERVICE
[Unit]
Description=Smart Organizer Oneshot
After=network.target

[Service]
Type=oneshot
ExecStart=${BIN_DIR}/smart-organizer --once
EOFSERVICE

cat > "${CONFIG_DIR}/systemd/user/smart-organizer.timer" << EOFSERVICE
[Unit]
Description=Smart Organizer Timer
Requires=smart-organizer-timer.service

[Timer]
OnBootSec=15min
OnUnitActiveSec=1h
AccuracySec=1min
Persistent=true

[Install]
WantedBy=timers.target
EOFSERVICE

# Install backup timer if backup.sh exists
if [[ -f "${BIN_DIR}/backup.sh" ]]; then
  cat > "${CONFIG_DIR}/systemd/user/backup.service" << EOFSERVICE
[Unit]
Description=Backup Script Oneshot
After=network.target

[Service]
Type=oneshot
ExecStart=${BIN_DIR}/backup.sh
EOFSERVICE

  cat > "${CONFIG_DIR}/systemd/user/backup.timer" << EOFSERVICE
[Unit]
Description=Backup Timer
Requires=backup.service

[Timer]
OnCalendar=weekly
AccuracySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOFSERVICE
fi

# Install maintenance timer if maintenance.sh exists
if [[ -f "${BIN_DIR}/maintenance.sh" ]]; then
  cat > "${CONFIG_DIR}/systemd/user/maintenance.service" << EOFSERVICE
[Unit]
Description=Maintenance Script Oneshot
After=network.target

[Service]
Type=oneshot
ExecStart=${BIN_DIR}/maintenance.sh --auto
EOFSERVICE

  cat > "${CONFIG_DIR}/systemd/user/maintenance.timer" << EOFSERVICE
[Unit]
Description=Maintenance Timer
Requires=maintenance.service

[Timer]
OnCalendar=weekly
AccuracySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOFSERVICE
fi

v systemctl --user daemon-reload
v systemctl --user enable --now smart-organizer.service || true
v systemctl --user enable --now smart-organizer.timer || true
if [[ -f "${BIN_DIR}/backup.sh" ]]; then
  v systemctl --user enable --now backup.timer || true
fi
if [[ -f "${BIN_DIR}/maintenance.sh" ]]; then
  v systemctl --user enable --now maintenance.timer || true
fi

printf "${STY_GREEN}Smart Organizer installed successfully!${STY_RST}\n"
printf "  Run: smart-organizer --dry-run\n"
printf "  Run: smart-organizer --clean system\n"
printf "  Service: systemctl --user status smart-organizer\n"
printf "  Timer: systemctl --user list-timers | grep smart-organizer\n"
printf "  Backup timer: systemctl --user list-timers | grep backup\n"
printf "  Maintenance timer: systemctl --user list-timers | grep maintenance\n"
