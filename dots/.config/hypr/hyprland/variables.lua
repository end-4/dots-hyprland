-- Default variables
-- Copy these to $HOME/.config/hypr/custom/variables.lua to make changes in a dotfiles-update-friendly manner

-- The folder within $HOME/.config/quickshell containing the config
hl.env("qsConfig", "ii")

-- Apps
-- PULL REQUESTS ADDING MORE WILL NOT BE ACCEPTED, CONFIG FOR YOURSELF
hl.env("terminal", "$HOME/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1' 'foot' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'")
hl.env("fileManager", "$HOME/.config/hypr/hyprland/scripts/launch_first_available.sh 'dolphin' 'nautilus' 'nemo' 'thunar' 'kitty -1 fish -c yazi'")
hl.env("browser", "$HOME/.config/hypr/hyprland/scripts/launch_first_available.sh 'google-chrome-stable' 'zen-browser' 'firefox' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'")
hl.env("codeEditor", "$HOME/.config/hypr/hyprland/scripts/launch_first_available.sh 'antigravity' 'code' 'codium' 'cursor' 'zed' 'zedit' 'zeditor' 'kate' 'gnome-text-editor' 'emacs' 'command -v nvim && kitty -1 nvim' 'command -v micro && kitty -1 micro'")
hl.env("officeSoftware", "$HOME/.config/hypr/hyprland/scripts/launch_first_available.sh 'wps' 'onlyoffice-desktopeditors' 'libreoffice'")
hl.env("textEditor", "$HOME/.config/hypr/hyprland/scripts/launch_first_available.sh 'kate' 'gnome-text-editor' 'emacs'")
hl.env("volumeMixer", "$HOME/.config/hypr/hyprland/scripts/launch_first_available.sh 'pavucontrol-qt' 'pavucontrol'")
hl.env("settingsApp", "XDG_CURRENT_DESKTOP=gnome $HOME/.config/hypr/hyprland/scripts/launch_first_available.sh 'qs -p $HOME/.config/quickshell/$qsConfig/settings.qml' 'systemsettings' 'gnome-control-center' 'better-control'")
hl.env("taskManager", "$HOME/.config/hypr/hyprland/scripts/launch_first_available.sh 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes' 'command -v btop && kitty -1 fish -c btop'")


-- Leave blank like this to load default config. Set to anything to not.
local dontLoadDefaultExecs = ""
local dontLoadDefaultGeneral = ""
local dontLoadDefaultRules = ""
local dontLoadDefaultKeybinds = ""
