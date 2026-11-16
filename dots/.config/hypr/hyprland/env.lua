local home_dir = os.getenv("HOME")

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Applications
-- Deduplicate so entries don't pile up on every reload (os.getenv returns the value we set last time)
local xdg_data_dirs_raw = home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. (os.getenv("XDG_DATA_DIRS") or "")
local xdg_data_dirs = {}
local xdg_data_dirs_seen = {}
for dir in xdg_data_dirs_raw:gmatch("[^:]+") do
    if not xdg_data_dirs_seen[dir] then
        xdg_data_dirs_seen[dir] = true
        table.insert(xdg_data_dirs, dir)
    end
end
hl.env("XDG_DATA_DIRS", table.concat(xdg_data_dirs, ":"))

-- Themes
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Virtual environment
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")
