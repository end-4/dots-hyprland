# dots-hyprland - Custom Features Fork

> **Fork of**: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (illogical-impulse)  
> **Customizations by**: tslove923  
> **Target Hardware**: Intel Lunar Lake (Arc GPU + NPU)

A personal fork of end-4's excellent dots-hyprland Quickshell configuration with custom features and hardware-specific enhancements. Each feature is developed in its own branch and can be used independently.

## 🌟 Custom Features

### 📊 [GPU & NPU Monitoring](../../tree/feature/gpu-npu-monitoring)
Real-time GPU and NPU usage indicators in the Quickshell bar, tailored for Intel Lunar Lake.

- **GPU**: DRM cycle counter monitoring (Render/Video/Compute engines) with frequency metrics
- **NPU**: True compute utilization via `npu_busy_time_us` sysfs interface
- Material Symbol icons: `stadia_controller` (GPU), `neurology` (NPU)
- Per-engine popup details with CPU/GPU frequency readouts
- Color-coded warnings at configurable thresholds
- Indicator order: CPU → GPU → NPU → Memory → Swap
- Requires `intel-gpu-tools` for GPU, NPU monitoring is built-in via sysfs

**Branch**: [`feature/gpu-npu-monitoring`](../../tree/feature/gpu-npu-monitoring) · [Documentation](GPU_NPU_MONITORING.md)

---

### 🎙️ [AI Assistant](../../tree/feature/ai-assistant)
Voice-activated AI assistant with wake word detection and NPU acceleration.

- **Wake word**: "Hey Jarvis" via openwakeword (~80ms latency, ~5-10% CPU)
- **NPU acceleration**: Optional OpenVINO backend for Intel Lunar Lake NPU
- **Audio coordination**: State machine prevents mic conflicts between wake word and voxd
- **Visual feedback**: Aurora glow effect on the AI panel when activated
- **Agent system** (WIP): Intent-based routing for web search, Spotify, email, browser tabs
- Packaged as an Arch Linux PKGBUILD with systemd user service

**Branch**: [`feature/ai-assistant`](../../tree/feature/ai-assistant) · [Documentation](AI-ASSISTANT-README.md)

---

### 🔒 [VPN Indicator](../../tree/feature/vpn-indicator)
Real-time VPN status indicator in the Quickshell bar.

- Green `vpn_lock` icon when connected, grey when disconnected
- Click to toggle VPN connection via custom script
- Supports OpenVPN, WireGuard, and tun0 interfaces
- Polls every 5 seconds with 2-second post-toggle refresh

**Branch**: [`feature/vpn-indicator`](../../tree/feature/vpn-indicator)

---

### 🤖 [GitHub Copilot Integration](../../tree/feature/copilot-integration)
Integrates GitHub Copilot as an AI model in the sidebar chat panel.

- Uses `gh copilot` CLI for authentication — no API key required
- Leverages existing Copilot subscription seamlessly
- Custom QML API strategy with full chat service (Ai.qml)

**Branch**: [`feature/copilot-integration`](../../tree/feature/copilot-integration)

---

### 🌍 [Custom View & World Clocks](../../tree/feature/custom-view)
UI enhancements to the sidebar and bar.

- **World clocks widget** in the sidebar with multiple timezone support
- **Work week number** displayed in the top bar clock
- US date format (MM/dd) in the bar
- Clocks sorted by UTC offset with "City, XX" labels

**Branch**: [`feature/custom-view`](../../tree/feature/custom-view)

---

### ⚙️ [Custom Configs](../../tree/feature/custom-configs)
Personal configuration customizations and QoL improvements.

- Custom Hyprland keybindings (Docker toggle, VPN shortcut, workspace management)
- `nm-applet` as headless NetworkManager secret agent
- Polkit fingerprint authentication support
- Custom autostart entries and resource display options

**Branch**: [`feature/custom-configs`](../../tree/feature/custom-configs)

---

### 🛜 [WiFi Reconnect Fix](../../tree/fix/wifi-reconnect-after-password)
Fixes a bug where WiFi failed to reconnect after entering a new password.

- `connectProc.exec()` was incorrectly toggling `.running` instead of calling `.exec()`
- Also fixes a null reference on retry

**Branch**: [`fix/wifi-reconnect-after-password`](../../tree/fix/wifi-reconnect-after-password)

---

## 📦 Installation

### Use All Features
```bash
# Clone this repository
git clone https://github.com/tslove923/dots-hyprland
cd dots-hyprland

# Merge all features into a combined branch
git checkout -b all-features
git merge feature/vpn-indicator
git merge feature/copilot-integration
git merge feature/custom-configs
git merge feature/custom-view
git merge feature/gpu-npu-monitoring
git merge feature/ai-assistant
git merge fix/wifi-reconnect-after-password

# Then install using the upstream installer
./setup install
```

### Use Individual Features
Each feature branch has its own installation instructions. Visit the branch README for details.

```bash
# Example: Install just GPU/NPU monitoring
git clone -b feature/gpu-npu-monitoring https://github.com/tslove923/dots-hyprland
cd dots-hyprland
# Follow instructions in GPU_NPU_MONITORING.md
```

### Development Workflow
For development and testing individual features against a live system:

```bash
# Sync a feature to your live config
bash scripts/sync_and_test.sh gpu-npu    # GPU/NPU monitoring
bash scripts/sync_and_test.sh vpn        # VPN indicator
bash scripts/sync_and_test.sh copilot    # Copilot integration
bash scripts/sync_and_test.sh keybinds   # Custom keybinds

# Pull changes back from live config
bash scripts/sync_and_test.sh pull

# Reload Quickshell to test: Super+Shift+R
```

## 🔄 Staying Updated

This fork tracks upstream changes from end-4's original repository:

```bash
git remote add upstream https://github.com/end-4/dots-hyprland
git fetch upstream
git merge upstream/main
```

## 📚 Original Repository

This is based on [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — an amazing Hyprland configuration (illogical-impulse). All credit for the base configuration goes to end-4 and contributors.

## 🤝 Contributing

Feel free to:
- Use these features in your own setup
- Suggest improvements via issues
- Submit pull requests for enhancements

## 📝 License

Same as the original repository. See [LICENSE](LICENSE) for details.

---

**Upstream**: [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland)  
**This Fork**: Custom features by tslove923
