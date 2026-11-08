-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

-- Internal stuff --
require("hyprland.lib")
require("hyprland.services")

-- Environment variables --
require("hyprland.env")
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end

-- Default configurations --
require("hyprland.execs")
require("hyprland.general")
require("hyprland.rules")
require("hyprland.colors")
require("hyprland.keybinds")

-- Custom configurations --
if is_file_exists(HOME .. "/.config/hypr/custom/execs.lua") then
    require("custom.execs")
end
if is_file_exists(HOME .. "/.config/hypr/custom/general.lua") then
    require("custom.general")
end
if is_file_exists(HOME .. "/.config/hypr/custom/rules.lua") then
    require("custom.rules")
end
if is_file_exists(HOME .. "/.config/hypr/custom/keybinds.lua") then
    require("custom.keybinds")
end

-- nwg-displays support --
if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then
    require("workspaces")
end

-- monitors.lua is loaded only while the Quickshell Displays feature is on.
-- Turning the feature off keeps the file and skips it here.
local function displays_feature_enabled()
    local config_home = os.getenv("XDG_CONFIG_HOME")
    if config_home == nil or config_home == "" then
        config_home = HOME .. "/.config"
    end
    local f = io.open(config_home .. "/illogical-impulse/config.json", "r")
    if f == nil then
        return false
    end
    local text = f:read("*a")
    f:close()
    if text == nil then
        return false
    end
    local body = text:match('"displays"%s*:%s*(%b{})')
    if body == nil then
        return false
    end
    return body:match('"enable"%s*:%s*true') ~= nil
end

if displays_feature_enabled() and is_file_exists(HOME .. "/.config/hypr/monitors.lua") then
    require("monitors")
end

-- Shell overrides --
require("hyprland.shellOverrides.main")
