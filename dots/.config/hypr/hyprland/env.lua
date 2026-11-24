local home_dir = os.getenv("HOME")

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Applications
local xdg_data_dirs = os.getenv("XDG_DATA_DIRS") or ""
for _, dir in ipairs({ "/usr/share", "/usr/local/share", "/var/lib/flatpak/exports/share", home_dir .. "/.local/share/flatpak/exports/share" }) do
    -- Don't add the same dir again when the config is reloaded
    if not (":" .. xdg_data_dirs .. ":"):find(":" .. dir .. ":", 1, true) then
        xdg_data_dirs = xdg_data_dirs == "" and dir or dir .. ":" .. xdg_data_dirs
    end
end
hl.env("XDG_DATA_DIRS", xdg_data_dirs)

-- Themes
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Virtual environment
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")
