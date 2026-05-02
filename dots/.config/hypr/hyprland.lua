-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

-- --- Environment variables ---
require("hyprland/env.lua")
-- hyprlang noerror true
require("custom/env.lua")
-- hyprlang noerror false

-- --- Other vars ---
require("hyprland/variables.lua")
-- hyprlang noerror true
require("custom/variables.lua")
-- hyprlang noerror false

-- --- Defaults ---
-- hyprlang if !dontLoadDefaultExecs
require("hyprland/execs.lua")
-- hyprlang endif
-- hyprlang if !dontLoadDefaultGeneral
require("hyprland/general.lua")
-- hyprlang endif
-- hyprlang if !dontLoadDefaultRules
require("hyprland/rules.lua")
-- hyprlang endif
-- hyprlang if !dontLoadDefaultColors
require("hyprland/colors.lua")
-- hyprlang endif
-- hyprlang if !dontLoadDefaultKeybinds
require("hyprland/keybinds.lua")
-- hyprlang endif

-- --- Custom ---
-- hyprlang noerror true
require("custom/execs.lua")
-- hyprlang noerror true
require("custom/general.lua")
-- hyprlang noerror true
require("custom/rules.lua")
-- hyprlang noerror true
require("custom/keybinds.lua")
-- hyprlang noerror false

-- --- nwg-displays support ---
require("workspaces.lua")
require("monitors.lua")

-- --- Shell overrides ---
require("hyprland/shellOverrides/main.lua")
