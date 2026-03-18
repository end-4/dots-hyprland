# dots-hyprland (tslove923 fork)

> **Fork of**: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) · illogical-impulse  
> Custom features for Intel Lunar Lake laptops, voice AI, home automation, and daily-driver QoL

---

## 🚀 Quick Start — Apply All Features

After a fresh `./setup install` from `main`, run one script to merge and deploy every feature branch:

```bash
./apply-all-features.sh
```

This creates a temporary integration branch, merges all 8 feature branches in the correct order, auto-resolves conflicts, backs up your config, and deploys everything. See [Apply All Features](#-apply-all-features-script) below for details.

---

## ✨ Feature Branches

### 🎮 GPU & NPU Monitoring — [`feature/gpu-npu-monitoring`](https://github.com/tslove923/dots-hyprland/tree/feature/gpu-npu-monitoring)

Real-time GPU and NPU usage indicators for Intel Lunar Lake SoCs in the Quickshell status bar.

- **GPU**: DRM cycle counter monitoring (render, video, compute engines) with live frequency
- **NPU**: `npu_busy_time_us` delta method for granular utilization %, frequency, memory
- **UI**: Indicators in bar, vertical bar, popup tooltip, and full overlay
- **Config**: Adjustable warning thresholds (default 90%), always-show toggles

<details>
<summary>Files changed</summary>

| File | Description |
|------|-------------|
| `services/ResourceUsage.qml` | GPU/NPU monitoring logic with DRM fdinfo parsing |
| `modules/ii/bar/Resources.qml` | GPU/NPU indicators in horizontal bar |
| `modules/ii/verticalBar/Resources.qml` | GPU/NPU indicators in vertical bar |
| `modules/ii/bar/ResourcesPopup.qml` | GPU/NPU info in hover tooltip |
| `modules/ii/overlay/resources/Resources.qml` | GPU/NPU tabs with usage graphs |
| `modules/common/Config.qml` | Config options (thresholds, always-show) |
</details>

---

### 🔒 VPN Status Indicator — [`feature/vpn-indicator`](https://github.com/tslove923/dots-hyprland/tree/feature/vpn-indicator)

VPN connection indicator in the system bar with click-to-toggle.

- 🟢 Green when connected, ⚫ grey when disconnected
- Click to toggle VPN via user script
- Detects OpenVPN, WireGuard, and tun0 interfaces
- 5-second polling interval

<details>
<summary>Files changed</summary>

- `dots/quickshell/ii/services/VpnStatus.qml` (new)
- `dots/quickshell/ii/modules/ii/bar/BarContent.qml` (modified)
</details>

---

### 🤖 AI Assistant — [`feature/ai-assistant`](https://github.com/tslove923/dots-hyprland/tree/feature/ai-assistant)

Voice-activated AI assistant with wake word detection and agent-based task automation.

- **Wake word**: "Hey Jarvis" via openwakeword (~80ms latency, 5-10% CPU)
- **Voice-to-text**: voxd streaming transcription
- **Aurora glow**: Visual feedback effect on AI panel activation
- **Agent system**: Web search, Spotify, email, browser tab agents
- **NPU acceleration**: Optional OpenVINO-accelerated wake word detection
- All processing runs locally — no cloud dependencies

<details>
<summary>Files changed</summary>

- `ai-assistant/` — wake word detector, event handler, systemd service, install script
- `dots/quickshell/ii/services/AIAssistantState.qml` (new)
- `dots/quickshell/ii/modules/ii/sidebarLeft/AuroraGlow.qml` (new)
</details>

---

### 💬 GitHub Copilot Integration — [`feature/copilot-integration`](https://github.com/tslove923/dots-hyprland/tree/feature/copilot-integration)

GitHub Copilot as an AI backend in the Quickshell AI chat panel.

- Routes AI panel queries through `gh copilot` CLI
- Seamless integration with existing AI chat UI
- External config for API settings

<details>
<summary>Files changed</summary>

- `dots/quickshell/ii/services/Ai.qml` (new overlay)
- `dots/quickshell/ii/services/ai/CopilotCliApiStrategy.qml` (new)
- `dots/illogical-impulse/config.json` (new — Copilot config)
</details>

---

### ⌨️ Custom Configs & Keybinds — [`feature/custom-configs`](https://github.com/tslove923/dots-hyprland/tree/feature/custom-configs)

Personal keybinds, service toggles, and startup scripts.

- **Super+Alt+D** — Toggle Docker on/off
- **Super+Alt+V** — VPN toggle (polkit GUI auth)
- **Super+Alt+P** — Proxy toggle with notification
- **Super+Alt+A/Z** — Nova wake word / TTS toggle
- **Super+A** — Nova type command
- **Super+C/V/X** — Universal copy/paste/cut (sendshortcut)
- **Super+Alt+B** — Bluetooth TUI
- Startup apps script, nm-applet as headless secret agent

<details>
<summary>Files changed</summary>

- `dots/.config/hypr/custom/keybinds.conf`
- `dots/.config/hypr/custom/execs.conf`
- `dots/.config/hypr/custom/scripts/` — toggle_docker.sh, nova_toggle_wake.sh, nova_toggle_tts.sh, startup-apps.sh
- `dots/.config/hypr/hyprland/keybinds.conf` — Super+C/V remapping
</details>

---

### 🕐 US Date Format & World Clocks — [`feature/us-clock-view-worldclocks`](https://github.com/tslove923/dots-hyprland/tree/feature/us-clock-view-worldclocks)

US-style date formatting and world clock panel in the right sidebar.

- Top bar date changed to MM/dd format
- World clocks panel in sidebar (sorted by UTC offset)
- Consistent "City, XX" label format

<details>
<summary>Files changed</summary>

- `modules/common/Config.qml` — date format strings
- `modules/ii/bar/ClockWidget.qml` — work week display
- `modules/ii/sidebarRight/SidebarRightContent.qml` — world clocks integration
- `modules/ii/sidebarRight/WorldClocks.qml` (new)
- `services/DateTime.qml` — date formatting
</details>

---

### 🏠 Home Assistant Integration — [`feature/homeassistant-integration`](https://github.com/tslove923/dots-hyprland/tree/feature/homeassistant-integration)

Home Assistant panel in the top bar for smart home control.

- HomeKit-inspired entity categories (cameras, lights, locks, covers, climate, appliances)
- Configurable polling interval, external config file support
- Device count indicator (toggleable)
- Settings UI in Quickshell settings panel

<details>
<summary>Files changed</summary>

- `services/HomeAssistant.qml` (new)
- `modules/ii/bar/BarContent.qml`, `modules/ii/bar/home/HomeBar.qml`, `modules/ii/bar/home/HomePopup.qml` (new)
- `modules/settings/BarConfig.qml`, `modules/settings/ServicesConfig.qml` (new)
- `modules/common/Config.qml` — homeAssistant config block
</details>

---

### 🖥️ Overview Monitor Binding — [`feature/overview-monitor-binding-dropdown`](https://github.com/tslove923/dots-hyprland/tree/feature/overview-monitor-binding-dropdown)

Workspace monitor binding dropdown in the overview widget, plus universal copy/paste keybinds.

- Dropdown to bind workspaces to monitors in overview
- **Super+C/V** — universal copy/paste via ydotool
- **Super+Shift+V** — clipboard history (moved from Super+V)

<details>
<summary>Files changed</summary>

- `modules/ii/overview/OverviewWidget.qml` — monitor binding dropdown
- `dots/.config/hypr/hyprland/keybinds.conf` — universal copy/paste
</details>

---

### 🎵 MPRIS Active Player Fix — [`feature/mpris-active-player-fix-main`](https://github.com/tslove923/dots-hyprland/tree/feature/mpris-active-player-fix-main)

Fixes media player selection so the currently playing source takes priority.

- Browser media (Chromium, Firefox) now properly detected
- Active player prioritized over paused/stopped players
- 3-file fix, minimal and clean

<details>
<summary>Files changed</summary>

- `modules/ii/bar/Media.qml`
- `modules/ii/mediaControls/MediaControls.qml`
- `services/MprisController.qml`
</details>

---

### 📧 Email/Todo Click-to-Open — [`feature/nova-email-todo-open`](https://github.com/tslove923/dots-hyprland/tree/feature/nova-email-todo-open)

Click email items in the todo sidebar to open them, plus auto-refresh.

- Click email todos to open in Evolution or Outlook Web
- EWS email click-to-open via cached message URLs
- Auto-refresh todo file without restarting Quickshell
- *Also includes*: GPU/NPU monitoring, VPN indicator, AI assistant (branch lineage)

<details>
<summary>Files changed</summary>

- `modules/ii/sidebarRight/todo/TaskList.qml`
- `services/Todo.qml`
- `services/ResourceUsage.qml` (GPU/NPU)
</details>

---

### 📶 WiFi Reconnect Fix — [`fix/wifi-reconnect-after-password`](https://github.com/tslove923/dots-hyprland/tree/fix/wifi-reconnect-after-password)

Properly re-executes `nmcli connect` after a WiFi password change.

<details>
<summary>Files changed</summary>

- `services/Network.qml` — 1 file, 5 lines changed
</details>

---

## 📦 Apply All Features Script

[`apply-all-features.sh`](https://github.com/tslove923/dots-hyprland/blob/feature/gpu-npu-monitoring/apply-all-features.sh) merges all branches above into a single integration and deploys to your live config.

### Merge Order

The script merges in dependency-aware order to minimize conflicts:

| # | Branch | Merges cleanly? |
|---|--------|-----------------|
| 1 | `fix/wifi-reconnect-after-password` | ✅ Clean |
| 2 | `feature/mpris-active-player-fix-main` | ✅ Clean |
| 3 | `feature/copilot-integration` | ⚡ README conflicts → auto-resolved |
| 4 | `feature/custom-configs` | ⚡ README conflicts → auto-resolved |
| 5 | `feature/us-clock-view-worldclocks` | ⚡ Keybinds conflict → auto-resolved |
| 6 | `feature/homeassistant-integration` | ⚡ README conflict → auto-resolved |
| 7 | `feature/overview-monitor-binding-dropdown` | ⚡ Keybinds conflict → auto-resolved |
| 8 | `feature/nova-email-todo-open` | ⚡ README conflicts → auto-resolved |

### What It Does

1. Creates a temporary integration branch from `main`
2. Sequentially merges all 8 feature branches
3. Auto-resolves known conflicts (READMEs → accept theirs, keybinds → custom-configs version for custom, accept theirs for hyprland core)
4. Backs up `~/.config` to `~/.config-backup-features-<timestamp>`
5. Deploys merged configs via rsync (quickshell, hypr, fish, overlay QML, etc.)
6. Optionally installs the AI assistant wake-word systemd service
7. Verifies critical files and reloads Hyprland

### Usage

```bash
# Full deploy (recommended for fresh install)
./apply-all-features.sh

# Preview only — create integration branch without deploying
./apply-all-features.sh --dry-run

# Deploy without AI assistant
./apply-all-features.sh --no-ai-assistant

# Keep integration branch after deploy for inspection
./apply-all-features.sh --keep-branch

# Skip backup (not recommended)
./apply-all-features.sh --no-backup
```

### Restoring from Backup

```bash
cp -a ~/.config-backup-features-<timestamp>/.config/* ~/.config/
hyprctl reload
```

---

## 🔧 Requirements

- [Hyprland](https://hyprland.org/) with [Quickshell](https://github.com/quickshell-mirror/quickshell)
- Arch Linux (tested), Fedora (partial support)
- Intel Lunar Lake SoC (for GPU/NPU monitoring; other features work on any hardware)
- Optional: `intel-gpu-tools`, `openwakeword`, `voxd`, `gh` CLI (for Copilot)

## 📜 License

Same as base repository — see [LICENSE](../LICENSE)

---

**Upstream**: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)  
**Fork by**: tslove923
