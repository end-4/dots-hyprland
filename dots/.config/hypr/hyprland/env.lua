local function parse_envs(str)
    local envs = ""
    local rstr = str
    for w in str:gmatch("$[%w_]+") do
        if not string.match(envs, w) then
            envs = w .. " " .. envs
        end
    end
    for w in envs:gmatch("[%w_]+") do
        local env = os.getenv(w)
        if env then
            rstr = string.gsub(rstr, "$"..w, env)
        else
            rstr = string.gsub(rstr,"$".. w, "")
        end
    end
    return rstr
end

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Applications
hl.env("XDG_DATA_DIRS", parse_envs("$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:$XDG_DATA_DIRS"))

-- Themes
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")

-- Virtual environment
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", parse_envs("$HOME/.local/state/quickshell/.venv"))