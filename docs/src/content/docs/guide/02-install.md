---
title: Installation
description: How to install this fork of dots-hyprland on Arch Linux
---

## Prerequisites

- **Arch Linux** (or an Arch-based distro like EndeavourOS or CachyOS)
- **An AUR helper** such as [yay](https://github.com/Jguer/yay)
- **Git** installed
- A working internet connection

:::note
Community-supported distros include Fedora and Gentoo. See [upstream docs](https://ii.clsty.link/en/ii-qs/01setup) for details on those platforms.
:::

## Clone the fork

```bash
git clone https://github.com/omsenjalia/dots-hyprland.git ~/dots-hyprland
cd ~/dots-hyprland
```

## Automated installation

The install script auto-detects your distro and installs all dependencies:

```bash
./setup install
```

This will:
1. Install all required packages via your package manager
2. Set up permissions and services
3. Copy config files to `~/.config/`
4. Run any custom additions from `dots/custom/*.sh`

### What the custom scripts install

This fork's `dots/custom/packages.sh` installs these additional packages:

- `zen-browser` — privacy-focused browser
- `claude-code` — Claude AI coding assistant
- `antigravity` — Antigravity AI agent
- `ollama` — local AI model runtime
- `obs-studio` — screen recording
- `vlc` — media player
- `vesktop` — Discord client
- `hermes-agent-git` — Hermes AI agent

## Post-installation

### Required services

```bash
# Power profile cycling (for Fn+Q support)
sudo systemctl enable --now power-profiles-daemon

# Ollama (auto-started by exec-once, but can also be a service)
sudo systemctl enable --now ollama
```

### Optional dependencies

```bash
# YouTube Downloader module
yay -S yt-dlp

# Wallpaper Slideshow folder browser
yay -S zenity
```

### Launch Hyprland

Log out and select **Hyprland** from your display manager, or from a TTY:

```bash
Hyprland
```

On first launch, the setup wizard will run automatically to configure monitors and initial settings.

## Updating

### Sync with this fork

```bash
cd ~/dots-hyprland
git pull origin main
./setup install
```

### Sync with upstream

```bash
cd ~/dots-hyprland
git fetch upstream
git merge upstream/main
# Resolve any conflicts (see Troubleshooting)
./setup install
```

:::caution
When upstream makes breaking changes (like the `.conf` → `.lua` migration), merge conflicts will need manual resolution. Check the [AI Agent Changelog](/ai-agents/changelog/) for notes on recent upstream syncs.
:::

## Uninstalling

```bash
cd ~/dots-hyprland
./setup uninstall
```

This removes copied config files but leaves your `dots/custom/` additions intact.
