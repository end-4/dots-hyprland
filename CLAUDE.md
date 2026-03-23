# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is **end_4's Hyprland dotfiles** - a comprehensive Linux desktop configuration featuring:
- **Hyprland** as the Wayland compositor
- **Quickshell** (QtQuick-based widget system) for the status bar, sidebars, panels, and desktop widgets
- **Material Design 3** inspired UI with accessible auto-generated colors
- **AI integration** (Gemini API and Ollama) with sidebar assistant
- Installation via `./setup` script supporting Arch, Fedora, Gentoo, openSUSE, Debian, and Nix-based distributions

## Workflow Orchestration
### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity
### 2. Subagent Strategy
- Use subagents liberally to keep main contect window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problens, throw more compute at it via subagents
- One tack per subagent for focused execution
### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project
### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness
### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, chvious fixes - don't over-engineer
- Challenge your own work before presenting it
### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how
## Task Management
1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections
## Core Principles
- **Simplicity First**: Make every change as simple as possible. Inpact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.


## Common Commands

### Installation

```bash
# Full installation (runs all steps)
./setup install

# Partial installations
./setup install-deps    # Install dependencies only
./setup install-setups  # Setup permissions/services only
./setup install-files   # Copy config files only

# Installation options
./setup install --force              # Force mode without any confirmation (DANGEROUS)
./setup install --firstrun           # Act like it's the first run
./setup install --clean              # Clean build cache first
./setup install --skip-sysupdate     # Skip "sudo pacman -Syu"
./setup install --skip-backup        # Skip backing up existing configs
./setup install --skip-quickshell    # Skip Quickshell config
./setup install --skip-hyprland      # Skip Hyprland config
./setup install --skip-fish          # Skip Fish config
./setup install --core               # Skip plasma-browser-intg, fish, fontconfig, misc
./setup install --exp-files          # Use experimental yaml-based file copying
./setup install --via-nix            # Use Nix/Home-manager (experimental)
./setup install --ignore-outdate     # Skip outdate check for community distros
```

### Updates

```bash
# Experimental updates
./setup exp-update              # Update configs without full reinstall
./setup exp-update -n           # Dry-run mode (show what would change)
./setup exp-update --skip-notice # Skip notice prompts
./setup exp-update --non-interactive # Non-interactive mode

./setup exp-merge               # Merge upstream changes via git rebase
```

### Diagnostic & Testing

```bash
# Generate diagnostic report
./diagnose              # Creates diagnose.result file, optionally uploads to 0x0.st

# Testing
./setup virtmon         # Create virtual monitors for testing multi-monitor setups
./setup checkdeps       # Check if packages exist in AUR/repos
./setup resetfirstrun   # Reset firstrun state

# Run test suite
bash sdata/subcmd-exp-update/exp-update-tester.sh
```

### Uninstall

```bash
./setup uninstall       # Uninstall dotfiles
```

## Repository Structure

```
dots-hyprland/
├── dots/                          # Configuration files to be installed
│   └── .config/
│       ├── hypr/                  # Hyprland config (.conf files)
│       │   ├── hyprland/          # Main Hyprland configuration
│       │   ├── custom/            # User customizations (empty by default)
│       │   ├── hypridle.conf      # Idle management
│       │   ├── hyprland.conf      # Main config entry point
│       │   ├── hyprlock.conf      # Lock screen config
│       │   ├── monitors.conf      # Monitor configuration
│       │   └── workspaces.conf    # Workspace rules
│       ├── quickshell/ii/         # Main Quickshell configuration
│       │   ├── shell.qml          # Entry point
│       │   ├── settings.qml       # Settings application
│       │   ├── modules/           # UI modules
│       │   ├── services/          # Background services
│       │   ├── scripts/           # Shell scripts for various functions
│       │   ├── defaults/          # Default configurations
│       │   ├── assets/            # Icons and images
│       │   └── translations/        # i18n support
│       ├── kitty/                 # Terminal emulator config
│       ├── matugen/               # Material color generation
│       ├── mpv/                   # Video player config
│       └── ...                    # Other app configs
├── sdata/                         # Install script data
│   ├── lib/                       # Shared shell functions
│   ├── subcmd-*/                  # Subcommand implementations
│   ├── dist-arch/                 # Arch Linux PKGBUILDs
│   ├── dist-fedora/               # Fedora-specific data
│   ├── dist-gentoo/               # Gentoo-specific data
│   ├── dist-nix/                  # Nix/home-manager configs
│   └── uv/                        # Python requirements
├── dots-extra/via-nix/            # Alternative Nix installation
├── dots/custom/                   # User custom additions (preserved across updates)
├── setup                          # Main installation script
└── diagnose                       # Diagnostic script
```

### On-Screen Keyboard Layouts

**Location**: `Config.options.osk.layout`

Available layouts in `modules/ii/onScreenKeyboard/`:
- `qwerty_full` - Full QWERTY with numbers and symbols
- `qwerty_compact` - Compact QWERTY
- `nordic_full` - Nordic layout
- `nordic_compact` - Compact Nordic

### Bar Corner Styles

**Config**: `Config.options.bar.cornerStyle`

- `0` - Hug (bar touches screen edges, default)
- `1` - Float (bar floats with gaps, shadow enabled via `Config.options.bar.floatStyleShadow`)
- `2` - Plain rectangle (no rounding, borderless)

### Clock Styles (Background Widget)

**Config**: `Config.options.background.widgets.clock.style`

- `cookie` - Cookie-shaped analog clock (configurable sides: 3-∞, sine/cosine based)
- `digital` - Digital clock with customizable font and alignment

**Cookie Clock Options**:
- Sides: 3 (triangle), 4 (square), 6 (hexagon), 14 (default "circle")
- Hand styles: classic, fill, hollow, dot, line
- Date indicator: border, rect, bubble, hide
- AI styling option for automatic color adaptation

## Architecture Deep Dive

### Quickshell Configuration (`dots/.config/quickshell/ii/`)

#### Entry Point (`shell.qml`)

The main entry point sets up the Quickshell environment:

```qml
//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
////@ pragma Env QT_SCALE_FACTOR=1  // UI scale factor (commented by default)
```

**Panel Families:** Two interchangeable UI layouts:
- `"ii"` (default) - illogical-impulse style with vertical bar and sidebars
- `"waffle"` - Windows 11-inspired style with taskbar and action center

Switch via `panelFamilyCycle` global shortcut (Ctrl+Super+P) or set `Config.options.panelFamily`.

#### Module Organization

**Common Modules** (`modules/common/`):
- `Config.qml` - Singleton configuration manager (JSON-based)
- `Appearance.qml` - Singleton theme/colors/animation manager
- `Directories.qml` - Path constants
- `Icons.qml` - Icon name constants
- `Images.qml` - Image asset constants
- `Persistent.qml` - Persistent storage wrapper
- `functions/` - Utility functions (ColorUtils, DateUtils, FileUtils, Fuzzy, Levendist, NotificationUtils, ObjectUtils, Session, StringUtils)
- `models/` - Data models (AdaptedMaterialScheme, AnimatedTabIndexPair, FolderListModelWithHistory, IndexModel, LauncherSearchResult, quickToggles/*)
- `panels/` - Shared panel components (lock/*)
- `utils/` - Utility components (ImageDownloaderProcess, ScreenshotAction, TempScreenshotProcess)
- `widgets/` - 100+ reusable widgets following Material Design 3

**Panel Family: ii** (`modules/ii/`):
- `bar/` - Status bar (top/left), includes workspaces, active window, media, resources, battery, system tray, clock
- `overview/` - Application launcher/workspace overview with search
- `sidebar/` - Left and right sidebars (AI, system toggles, calendar, notifications)
- `background/` - Desktop background with widgets (clock, weather)
- `cheatsheet/` - Keybinding reference (Super+/)
- `dock/` - Optional application dock
- `lock/` - Screen lock interface
- `mediaControls/` - Media player popup
- `notificationPopup/` - Notification toasts
- `onScreenDisplay/` - Volume/brightness change feedback
- `onScreenKeyboard/` - Virtual keyboard
- `overlay/` - Gaming overlay with crosshair, notes, FPS limiter
- `polkit/` - Authentication dialog
- `regionSelector/` - Screenshot region selection

**Panel Family: waffle** (`modules/waffle/`):
- Windows 11-inspired interface with taskbar and Action Center

**Settings** (`modules/settings/`):
- Settings application with categorized configuration pages
- Accessible via Super+I or `settings.qml` directly

#### Assets (`assets/`)

**Icons** (`assets/icons/`):
- Custom symbolic icons for distro logos: `arch-symbolic.svg`, `fedora-symbolic.svg`, `gentoo-symbolic.svg`, `cachyos-symbolic.svg`, `endeavouros-symbolic.svg`, `debian-symbolic.svg`
- AI provider icons: `openai-symbolic.svg`, `deepseek-symbolic.svg`, `google-gemini-symbolic.svg` (symlink), `ai-openai-symbolic.svg` (symlink)
- Service icons: `cloudflare-dns-symbolic.svg`, `crosshair-symbolic.svg`, `github-symbolic.svg`, `flatpak-symbolic.svg`
- Desktop icon: `desktop-symbolic.svg`, `linux-symbolic.svg`, `microsoft-symbolic.svg`, `spark-symbolic.svg`
- `fluent/` subdirectory - Fluent Design system icons

**Images** (`assets/images/`):
- Placeholder images and UI assets

#### Services (`services/`)

Background services providing functionality:

| Service | Purpose |
|---------|---------|
| `Ai.qml` | AI chat interface (Gemini, Ollama, custom models) |
| `AppSearch.qml` | Application search indexing |
| `Audio.qml` | Audio control (wpctl) |
| `Battery.qml` | Battery status monitoring |
| `BluetoothStatus.qml` | Bluetooth state management |
| `Booru.qml` | Image board integration |
| `Brightness.qml` | Brightness control |
| `Cliphist.qml` | Clipboard history (wlclipboar + cliphist) |
| `ConflictKiller.qml` | Kill conflicting notification daemons/trays |
| `DateTime.qml` | Time and date utilities |
| `EasyEffects.qml` | Audio effects integration |
| `Emojis.qml` | Emoji database for search |
| `FirstRunExperience.qml` | First-time user setup |
| `HyprlandData.qml` | Hyprland IPC data binding |
| `HyprlandKeybinds.qml` | Keybinding parsing from config |
| `Hyprsunset.qml` | Night light (blue light filter) |
| `Idle.qml` | Idle detection for auto-lock |
| `KeyringStorage.qml` | GNOME keyring integration |
| `LauncherApps.qml` | Application launcher data |
| `LauncherSearch.qml` | Search aggregation |
| `MaterialThemeLoader.qml` | Color scheme loading from matugen |
| `MprisController.qml` | Media player control |
| `Network.qml` | Network status |
| `Notifications.qml` | Notification management |
| `PolkitService.qml` | PolicyKit authentication |
| `Privacy.qml` | Privacy features (work safety mode) |
| `ResourceUsage.qml` | CPU/RAM/Swap monitoring |
| `SongRec.qml` | Music recognition (SongRec) |
| `TaskbarApps.qml` | Taskbar application tracking |
| `Todo.qml` | Todo list service |
| `Translation.qml` | Translation service (translate-shell) |
| `TrayService.qml` | System tray (StatusNotifierItem) |
| `Updates.qml` | Package update checking |
| `Wallpapers.qml` | Wallpaper management and color generation |
| `Weather.qml` | Weather data fetching |
| `Ydotool.qml` | Virtual input device control |

#### Quick Toggle Models (`modules/common/models/quickToggles/`)

System toggle implementations for sidebar/quick settings:
- `AudioToggle.qml` - Audio output toggle
- `BluetoothToggle.qml` - Bluetooth on/off
- `CloudflareWarpToggle.qml` - Cloudflare WARP VPN
- `ColorPickerToggle.qml` - Color picker tool
- `DarkModeToggle.qml` - Dark/light theme
- `EasyEffectsToggle.qml` - Audio effects pipeline
- `IdleInhibitorToggle.qml` - Prevent screen lock
- `MicToggle.qml` - Microphone mute
- `MusicRecognitionToggle.qml` - Song recognition (SongRec)
- `NetworkToggle.qml` - Network on/off
- `NightLightToggle.qml` - Blue light filter (hyprsunset)
- `NotificationToggle.qml` - Do not disturb mode
- `OnScreenKeyboardToggle.qml` - Virtual keyboard toggle
- `PowerProfilesToggle.qml` - Power profile switching (balanced/performance)
- `QuickToggleModel.qml` - Base model for all toggles
- `ScreenSnipToggle.qml` - Screenshot tool activation

Important shell scripts:
- `colors/switchwall.sh` - Wallpaper switcher with color generation
- `colors/applycolor.sh` - Apply color scheme to various apps
- `ai/gemini-*.sh` - Gemini AI integration scripts
- `ai/show-installed-ollama-models.sh` - Ollama model management
- `images/*.sh` - Image processing (regions, thumbnails)
- `videos/record.sh` - Screen recording with wf-recorder
- `keyring/*.sh` - Keyring unlock/lookup scripts
- `thumbnails/*.sh` - Thumbnail generation
- `musicRecognition/recognize-music.sh` - Song recognition

#### Configuration System

**Main Config** (`modules/common/Config.qml`):
- JSON-based configuration stored at `~/.config/quickshell/ii/config.json`
- Hot-reload: Changes apply immediately
- Nested property access: `Config.options.bar.verbose`
- Default values defined in JsonAdapter with full schema

**Key Config Sections:**
```javascript
Config.options.panelFamily          // "ii" or "waffle"
Config.options.policies.ai          // 0: No, 1: Yes, 2: Local
Config.options.policies.weeb        // 0: No, 1: Open, 2: Closet
Config.options.ai.systemPrompt      // Default AI personality
Config.options.ai.extraModels       // Custom model definitions
Config.options.appearance.fonts       // Font families
Config.options.appearance.transparency
Config.options.appearance.wallpaperTheming
Config.options.bar.*                  // Bar configuration
Config.options.background.*           // Wallpaper and widgets
Config.options.dock.*                 // Dock settings
Config.options.launcher.*             // App launcher
Config.options.lock.*                 // Lock screen
Config.options.notifications.*        // Notification settings
Config.options.osk.*                  // On-screen keyboard
Config.options.overview.*             // Overview settings
Config.options.search.*               // Search configuration
Config.options.sidebar.*              // Sidebar configuration
Config.options.time.*                 // Time formats and pomodoro
Config.options.tray.*                   // System tray
Config.options.waffles.*              // Waffle-specific settings
Config.options.workSafety.*           // Work safety mode
```

**Appearance** (`modules/common/Appearance.qml`):
- Material Design 3 color system with 5 layers (Layer 0-4)
- Automatic transparency calculation based on wallpaper vibrancy
- Animation curves (expressive, emphasized, standard)
- Font families with variable font axis support
- Size constants for consistent UI scaling

### Hyprland Configuration

**Config Structure** (`dots/.config/hypr/`):
```
hypr/
├── hyprland.conf          # Main entry point
├── hypridle.conf          # Idle daemon config
├── hyprlock.conf          # Lock screen config
├── monitors.conf          # Monitor configuration (nwg-displays compatible)
├── workspaces.conf        # Workspace rules
├── custom/                # User customizations
│   ├── env.conf           # Environment variables
│   ├── execs.conf         # Autostart commands
│   ├── general.conf       # General settings
│   ├── rules.conf         # Window rules
│   └── keybinds.conf      # Additional keybindings
└── hyprland/              # Base configuration
    ├── colors.conf        # Color scheme (generated)
    ├── env.conf           # Environment variables
    ├── execs.conf         # Autostart commands
    ├── general.conf       # General settings
    ├── rules.conf         # Window rules
    ├── keybinds.conf      # Keybindings
    └── shellOverrides/    # Shell-specific overrides
```

**Keybindings** (excerpt from `hyprland/keybinds.conf`):
- `Super` - Hold for workspace numbers, tap for search
- `Super+/` - Show cheatsheet
- `Super+Enter` - Terminal
- `Super+Tab` - Overview/workspaces
- `Super+A` - Left sidebar (AI)
- `Super+N` - Right sidebar (toggles)
- `Super+V` - Clipboard history
- `Super+.` - Emoji picker
- `Super+Shift+S` - Screenshot region
- `Super+Shift+X/T` - OCR (text recognition)
- `Ctrl+Super+T` - Wallpaper selector
- `Ctrl+Super+R` - Restart Quickshell
- `Ctrl+Super+P` - Cycle panel families

**Window Management:**
- `Super+Q` - Close window
- `Super+F` - Fullscreen
- `Super+D` - Maximize
- `Super+Alt+Space` - Float/tile toggle
- `Super+[number]` - Switch to workspace
- `Super+Alt+[number]` - Move window to workspace
- `Super+mouse_drag` - Move/resize windows

### Color System

**Matugen** (`dots/.config/matugen/`):
- Material color generation from wallpaper
- Templates for various applications:
  - `hyprland/` - Hyprland border colors
  - `kde/` - KDE/kde-material-you-colors
  - `code/` - VS Code theme

**Color Script** (`scripts/colors/switchwall.sh`):
- Switches wallpaper and regenerates colors
- Updates Hyprland, kitty, Quickshell simultaneously
- Supports video wallpapers

### Installation System

**Setup Script Flow**:
1. **Greeting** (`0.greeting.sh`) - Show warnings/requirements
2. **Dependencies** (`1.deps-router.sh`) - Route to distro-specific installer
3. **Setups** (`2.setups.sh`) - Services, groups, Python venv
4. **Files** (`3.files.sh`) - Copy configuration files
5. **Custom** (`4.custom.sh`) - User custom additions

**Library Functions** (`sdata/lib/`):
- `environment-variables.sh` - XDG paths, styling constants
- `functions.sh` - Core utilities:
  - `v()` - Verbose execution with confirmation
  - `x()` - Execution with retry/ignore/error handling
  - `pause()` - Continue prompt
  - `install_cmds()` - Multi-distro package installation
  - `ensure_cmds()` - Auto-install missing commands
  - `backup_clashing_targets()` - Backup existing configs
  - `auto_update_git_submodule()` - Submodule management
  - `sudo_init_keepalive()` - Sudo session management
  - Logging functions (log_info, log_success, log_warning, log_error, log_header, log_die)
  - Security functions (sanitize_path, validate_path_in_directory)
- `package-installers.sh` - Custom package installers:
  - `install-Rubik()` - Google Rubik font
  - `install-Gabarito()` - Gabarito font
  - `install-OneUI()` - OneUI icon theme
  - `install-bibata()` - Bibata cursor theme
  - `install-MicroTeX()` - LaTeX rendering library
  - `install-uv()` - Python package manager
  - `install-python-packages()` - Python venv setup
- `dist-determine.sh` - OS detection and grouping

**Distro Support**:
| Distro | ID | Status |
|--------|-----|--------|
| Arch Linux | `arch` | Official |
| EndeavourOS | `arch` | Official |
| CachyOS | `arch` | Official |
| Gentoo | `gentoo` | Community |
| Fedora | `fedora` | Community |
| openSUSE | `suse` | Experimental (via Nix) |
| Debian/Ubuntu | `debian` | Experimental (via Nix) |

**Meta-packages** (Arch):
- `illogical-impulse-audio` - Audio tools (cava, pavucontrol, playerctl)
- `illogical-impulse-backlight` - Backlight control (brightnessctl, ddcutil)
- `illogical-impulse-basic` - Core utilities (cliphist, curl, jq, rsync)
- `illogical-impulse-fonts-themes` - Fonts and themes
- `illogical-impulse-hyprland` - Hyprland compositor
- `illogical-impulse-kde` - KDE integration (dolphin, systemsettings)
- `illogical-impulse-portal` - XDG desktop portals
- `illogical-impulse-python` - Python environment
- `illogical-impulse-screencapture` - Screenshot/recording tools
- `illogical-impulse-toolkit` - Various utilities (ydotool, upower)
- `illogical-impulse-widgets` - Widget tools (fuzzel, hyprlock, wlogout)
- `illogical-impulse-quickshell-git` - Quickshell from pinned commit
- `illogical-impulse-microtex-git` - LaTeX rendering

### Custom Additions System

**Purpose**: Allow users to add personal configurations without modifying core files.

**Location**: `dots/custom/`

**Files**:
- `packages.sh` - Extra packages to install via `yay -S`
- `files.sh` - Extra files to copy (use `cp_file` or `rsync_dir`)
- `commands.sh` - Extra shell commands to run
- `misc.sh` - Miscellaneous customizations

**Usage Pattern**:
```bash
custom_packages() {
    # firefox
    # vlc
    # thunderbird
}
```

Lines start with `#` - the script reads commented lines and executes them (removes `#` to get the value).

**Available Functions**:
- `cp_file <source> <dest>` - Copy single file
- `rsync_dir <source> <dest>` - Copy directory
- `rsync_dir__sync <source> <dest>` - Sync with deletion
- `rsync_dir__sync_exclude <source> <dest> <pattern...>` - Sync with excludes

### Experimental Update System

**exp-update** (`sdata/subcmd-exp-update/0.run.sh`):
- Updates configs without full reinstall
- Supports `.updateignore` file for excluding paths
- Dry-run mode (`-n`)
- Lock file mechanism to prevent concurrent runs
- Auto-detects repo structure (dots/ vs flat)

**exp-merge**:
- Uses git rebase to merge upstream changes
- Preserves local modifications

### Python Environment

**Location**: `$XDG_STATE_HOME/quickshell/.venv` (default: `~/.local/state/quickshell/.venv`)

**Managed by**: `uv` (modern Python package manager)

**Requirements**: `sdata/uv/requirements.txt`

**Key Python Dependencies**:
- Pillow - Image processing for thumbnails
- numpy - Image analysis
- requests - HTTP requests for AI services
- pyyaml - Configuration parsing

**Scripts using Python**:
- `scripts/images/find-regions-venv.sh` - Find busy regions in wallpaper
- `scripts/images/least-busy-region-venv.sh` - Optimal widget placement
- `scripts/thumbnails/thumbgen-venv.sh` - Thumbnail generation

### Translation System

**Location**: `dots/.config/quickshell/ii/translations/`

**Tools**:
- `tools/manage-translations.sh` - Translation management
- Supports Qt .ts files
- Guide available in `tools/guide/`

### Git Submodules

**Submodule**: `dots/.config/quickshell/ii/modules/common/widgets/shapes`
- Points to: `https://github.com/end-4/rounded-polygon-qmljs.git`
- Purpose: Rounded polygon shapes for QML

**Command**: `git submodule update --init --recursive`

### AI Integration

**Location**: `services/Ai.qml`, `modules/ii/sidebar/ai/`

**Supported Providers**:
- Google Gemini (API key required)
- Ollama (local models)
- Custom OpenAI-compatible endpoints (OpenRouter, etc.)

**Default Prompt Location**: `defaults/ai/prompts/`
- `ii-Default.md` - Default helpful assistant personality with casual tone
- `ii-Imouto.md` - Japanese little sister (imouto) personality
- `nyarch-Acchan.md` - Nyarch Linux personality (Acchan)
- `w-FourPointedSparkle.md` - Waffle panel family personality
- `w-OpenMechanicalFlower.md` - Alternative Waffle personality
- `NoPrompt.md` - Empty prompt (raw model behavior)

**Prompt Variables** (replaced at runtime):
- `{DISTRO}` - Current Linux distribution
- `{DE}` - Desktop environment (illogical-impulse)
- `{DATETIME}` - Current date and time
- `{WINDOWCLASS}` - Currently focused window class

**Features**:
- Markdown rendering in chat
- LaTeX math support (via MicroTeX, rendered with KaTeX)
- Tool calling (search via Gemini, custom functions)
- Image generation/analysis (if model supports)
- Configurable system prompt in settings

**Extra Models**:
Add custom models via `Config.options.ai.extraModels`:
```javascript
{
    "api_format": "openai",  // or "gemini"
    "description": "Model description",
    "endpoint": "https://api.example.com/v1/chat/completions",
    "key_id": "my_api_key",
    "model": "model-name",
    "name": "Display Name",
    "requires_key": true
}
```

### Work Safety Mode

**Purpose**: Hide sensitive content when on public/work networks

**Triggers**:
- Network name keywords (airport, cafe, company, guest, etc.)
- File keywords in recent files
- Link keywords in clipboard

**Actions**:
- Hide wallpaper
- Clear clipboard
- Disable certain features

**Config**: `Config.options.workSafety`

### Testing

**exp-update Test Suite** (`sdata/subcmd-exp-update/exp-update-tester.sh`):
Tests include:
- Syntax checking
- Help option handling
- Repository structure detection (dots/ vs flat)
- Ignore pattern matching (*.log, **temp**, etc.)
- Dry-run mode verification
- Shellcheck static analysis
- Lock file mechanism
- Safe read security (printf -v vs eval)

**Run**: `bash sdata/subcmd-exp-update/exp-update-tester.sh`

## XDG Paths

The setup uses standard XDG directories (from `sdata/lib/environment-variables.sh`):

| Variable | Default | Usage |
|----------|---------|-------|
| `$XDG_BIN_HOME` | `~/.local/bin` | User binaries |
| `$XDG_CACHE_HOME` | `~/.cache` | Cache files |
| `$XDG_CONFIG_HOME` | `~/.config` | **Configs installed here** |
| `$XDG_DATA_HOME` | `~/.local/share` | Data files |
| `$XDG_STATE_HOME` | `~/.local/state` | **Python venv at `quickshell/.venv`** |

**Important Files**:
- `$FIRSTRUN_FILE` - `~/.local/state/illogical-impulse/installed_true`
- `$INSTALLED_LISTFILE` - `~/.config/illogical-impulse/installed_listfile`
- `$BACKUP_DIR` - `~/ii-original-dots-backup`

## Environment Variables

**Required at Runtime**:
```bash
ILLOGICAL_IMPULSE_VIRTUAL_ENV="$XDG_STATE_HOME/quickshell/.venv"
QT_QUICK_CONTROLS_STYLE=Basic
QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
```

**Set by Hyprland** (`hyprland/env.conf`):
```bash
TERMINAL="kitty -1"
XDG_CURRENT_DESKTOP=Hyprland
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `setup` | Main entry point |
| `diagnose` | System diagnostic tool |
| `sdata/deps-info.md` | Detailed dependency info |
| `sdata/dist-arch/install-deps.sh` | Arch dependency installation |
| `sdata/subcmd-install/4.custom.sh` | Custom additions runner |
| `dots/custom/README.md` | Custom additions documentation |
| `dots/.config/quickshell/ii/shell.qml` | Quickshell entry point |
| `dots/.config/quickshell/ii/settings.qml` | Settings application |
| `dots/.config/quickshell/ii/modules/common/Config.qml` | Main configuration singleton |
| `dots/.config/quickshell/ii/modules/common/Appearance.qml` | Theme and color management |
| `dots/.config/quickshell/ii/GlobalStates.qml` | Global state management |
| `dots/.config/hypr/hyprland.conf` | Hyprland main config |
| `dots/.config/hypr/hyprland/keybinds.conf` | All keybindings |
| `dots/.config/hypr/custom/` | User customizations (safe to edit) |

## Development Notes

### Quickshell Pragmas

Entry point pragmas in `shell.qml`:
- `//@ pragma UseQApplication` - Uses QApplication instead of QGuiApplication
- `//@ pragma Env QS_NO_RELOAD_POPUP=1` - Disables reload popup
- `//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic` - Uses basic Qt style
- `//@ pragma Env QT_SCALE_FACTOR=1` - UI scale factor (commented by default)

### Panel Family Switching

The `panelFamily` option in `Config.options` can be set to `"ii"` (default) or `"waffle"`. Use the `panelFamilyCycle` global shortcut (Ctrl+Super+P) to cycle between them.

### Multi-Monitor Support

- Bar screen list: `Config.options.bar.screenList` (empty = all screens)
- Virtual monitors: `./setup virtmon` for testing
- Per-monitor workspaces: Hyprland workspace rules

### Adding a New Quick Toggle

1. Create model in `modules/common/models/quickToggles/`
2. Add to sidebar toggle grid configuration
3. Implement toggle logic using existing services

### Color Scheme Development

- Base colors from matugen (Material Design 3)
- Layers (0-4) for elevation
- Transparency auto-calculated from wallpaper vibrancy
- Override in `Appearance.qml` for development

## Troubleshooting

### Common Issues

**Quickshell not starting:**
- Check `$ILLOGICAL_IMPULSE_VIRTUAL_ENV` is set
- Run `qs -c ii` manually to see errors
- Check `hyprctl dispatch submap global` is in config

**Colors not updating:**
- Ensure `matugen-bin` is installed
- Check wallpaper path is valid
- Run `~/.config/quickshell/ii/scripts/colors/switchwall.sh`

**No audio in screen recordings:**
- Install `wf-recorder` with audio support
- Check `pactl list sources` for monitor source

**Panel family not switching:**
- Ensure `panelFamilyCycle` shortcut is bound
- Check `Config.options.panelFamily` is valid
- Restart Quickshell after changes

### Debug Commands

```bash
# Check Quickshell
qs -c ii ipc call TEST_ALIVE

# Check services
systemctl --user status ydotool
systemctl status bluetooth

# Check environment
echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV
echo $XDG_CONFIG_HOME

# Regenerate colors
~/.config/quickshell/ii/scripts/colors/switchwall.sh /path/to/wallpaper

# Reset firstrun
./setup resetfirstrun
```

## Contributing & Development

### Contribution Guidelines

**Important Rules**:
- **One feature per PR** - Don't combine multiple features or personal changes
- Features not personally wanted by maintainers must be configurable/optionally loaded
- Ask before working on big features to avoid wasted effort
- PRs welcome for community distro support (`sdata/dist-*`)

**Translation**:
- See `dots/.config/quickshell/ii/translations/tools/` for translation workflow
- Supports Qt .ts files

### Development Setup

**Full Setup (Recommended)**:
1. Install the dotfiles on a test user or system
2. Make changes in `~/.config/quickshell/ii/`
3. Test live with `pkill qs; qs -c ii`
4. Copy changes to fork, create PR

**Partial Setup (Minimal)**:
```bash
# Install only required packages
yay -S hyprland quickshell-git

# Copy Quickshell config
cp -r dots/.config/quickshell ~/.config/

# Run Quickshell
qs -c ii
```

**IDE Setup**:
- **LSP Support**: `touch ~/.config/quickshell/ii/.qmlls.ini` for QML language server
- **VSCode**: Install "Qt Qml" extension, set custom exe path to `/usr/bin/qmlls6`
- **Python**: Use uv venv at `$XDG_STATE_HOME/quickshell/.venv`

### Code Style

**QML/JS Style**:
- Use spaces, not tabs
- Space properties and children into meaningful groups
- Space between text and operators: `if (condition) { ... }` not `if(condition){...}`
- Prefer early return: `if (!condition) return;` over deep nesting
- Use `component` for reusable inline components

**Dynamic Loading**:
- Use `Loader` for conditionally loaded components
- Declare positioning properties (anchors) in the Loader, not the sourceComponent
- Use `FadeLoader` with `shown` property for fade animations

**Performance**:
- Don't require significant resources for minor features
- Fancy/impractical features must be disabled by default with config option
- Example: constantly rotating background clock is behind a config flag

### GitHub Workflows

**Auto-close Issue** (`.github/workflows/auto-close-issue.yml`):
- Automatically closes issues where user checks "I've ticked the checkboxes without reading"
- Posts comment explaining why, closes as "not_planned", and locks conversation

**Dist Update Notification** (`.github/workflows/dist-update-notification.yml`):
- Posts to Discussion #2140 when `sdata/dist-arch/` changes
- Notifies community distro maintainers of upstream changes

### Panel Family: Waffle

Windows 11-inspired panel family accessible via `panelFamilyCycle`.

**Activation**:
- Cycle: `Ctrl+Super+P` (cycles through all families: ii → waffle → ii...)
- Switch directly: `Super+W` (cycles panel family)
- IPC: `qs -c ii ipc call panelFamily cycle`

**Architecture**:
- Panel families defined in `dots/.config/quickshell/ii/panelFamilies/`
- `IllogicalImpulseFamily.qml` = ii style (bar, sidebars, overview, etc.)
- `WaffleFamily.qml` = Windows 11 style (taskbar, start menu, action center)
- Add new families: create new `*Family.qml` file, add to `shell.qml`'s `families` list

**Components**:
- Taskbar (bottom) with centered/start-aligned apps
- Action Center with quick toggles
- Start menu
- Calendar flyout

**Status**: Work in progress (WIP) - currently has basic bar functionality

## External Documentation

- **Main docs**: https://ii.clsty.link
- **GitHub**: https://github.com/end-4/dots-hyprland
- **Quickshell docs**: https://quickshell.outfoxxed.me/
- **Hyprland wiki**: https://wiki.hyprland.org/
- **Material Design 3**: https://m3.material.io/
- **Issue Discussion (dist updates)**: https://github.com/end-4/dots-hyprland/discussions/2140

## License

The project uses multiple licenses for different components. See `licenses/` directory for details:
- Main dotfiles: GNU GPL v3
- Quickshell: LGPL v3
- Various dependencies have their own licenses
