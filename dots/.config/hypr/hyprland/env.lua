-- ############ Wayland #############
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ######### Applications #########
hl.env("XDG_DATA_DIRS", "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share
")

-- ############ Themes #############
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- ######## Virtual envrionment #########
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", "~/.local/state/quickshell/.venv")
