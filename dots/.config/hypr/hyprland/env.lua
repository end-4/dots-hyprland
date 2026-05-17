local home_dir = os.getenv("HOME")

local function unique_paths(str)
	local seen = {}
	local result = {}

	for path in string.gmatch(str or "", "([^:]+)") do
		if not path:match("^%$[%w_]+$") and not seen[path] then
			seen[path] = true
			table.insert(result, path)
		end
	end

	return table.concat(result, ":")
end

local base_xdg = home_dir .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"
local current_xdg = os.getenv("XDG_DATA_DIRS") or ""

hl.env("XDG_DATA_DIRS", unique_paths(base_xdg .. ":" .. current_xdg))

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Themes
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Virtual environment
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", home_dir .. "/.local/state/quickshell/.venv")
