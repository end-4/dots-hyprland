-- Run with /usr/bin/lua from any working directory. This loads the real config,
-- but replaces Hyprland APIs and module imports so no command is executed.
local source = debug.getinfo(1, "S").source:sub(2)
local testDir = source:match("^(.*)/[^/]+$")
local keybinds = testDir .. "/../../dots/.config/hypr/hyprland/keybinds.lua"

local binds, commands = {}, {}
local function descriptor(name)
    return function(...)
        return { name = name, args = { ... } }
    end
end

local dsp = setmetatable({}, {
    __index = function(_, name)
        if name == "window" or name == "workspace" then
            return setmetatable({}, { __index = function(_, method) return descriptor("window." .. method) end })
        end
        return descriptor(name)
    end,
})

hl = {
    dsp = dsp,
    bind = function(key, action, options) binds[key] = { action = action, options = options } end,
    exec_cmd = function(command) commands[#commands + 1] = command end,
    get_config = function() return 1 end,
    define_submap = function(_, callback) callback() end,
    get_current_submap = function() return "" end,
    config = function() end,
    dispatch = function() end,
}
HOME = "/mock-home"
is_file_exists = function() return false end
terminal = "mock-terminal-command"
fileManager, browser, codeEditor = "mock-file-manager", "mock-browser", "mock-editor"
officeSoftware, textEditor, volumeMixer = "mock-office", "mock-text-editor", "mock-mixer"
settingsApp, taskManager = "mock-settings", "mock-task-manager"
qsConfig = "mock-config"
workspace_in_group = function(group) return group end

package.preload["hyprland.lib"] = function() end
package.preload["hyprland.variables"] = function() end
package.preload["custom.variables"] = function() end

assert(loadfile(keybinds))()

local terminalBind = assert(binds["SUPER + Return"], "missing Super+Return bind")
assert(type(terminalBind.action) == "function", "Super+Return must run its ordered command function")
commands = {}
terminalBind.action()
assert(commands[1] == terminal, "Super+Return must launch terminal first")
assert(commands[2] == "qs -c $qsConfig ipc call wallpapers terminalOpened",
    "Super+Return must notify wallpaper IPC after launching terminal")
assert(#commands == 2, "Super+Return must issue exactly those two commands")

local ctrlAltT = assert(binds["CTRL + ALT + T"], "missing Ctrl+Alt+T bind")
assert(type(ctrlAltT.action) == "table" and ctrlAltT.action.name == "exec_cmd",
    "Ctrl+Alt+T must only have the terminal exec action")
assert(ctrlAltT.action.args[1] == terminal, "Ctrl+Alt+T must launch the configured terminal")
print("terminal keybind integration tests passed")
