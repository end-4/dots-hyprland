-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

-- --- Environment variables ---
require("hyprland/env")
-- hyprlang noerror true
require("custom/env")
-- hyprlang noerror false

-- --- Other vars ---
require("hyprland/variables")
-- hyprlang noerror true
require("custom/variables")
-- hyprlang noerror false

-- --- Defaults ---
-- hyprlang if !dontLoadDefaultExecs
require("hyprland/execs")
-- hyprlang endif
-- hyprlang if !dontLoadDefaultGeneral
require("hyprland/general")
-- hyprlang endif
-- hyprlang if !dontLoadDefaultRules
require("hyprland/rules")
-- hyprlang endif
-- hyprlang if !dontLoadDefaultColors
require("hyprland/colors")
-- hyprlang endif
-- hyprlang if !dontLoadDefaultKeybinds
require("hyprland/keybinds")
-- hyprlang endif

-- --- Custom ---
-- hyprlang noerror true
require("custom/execs")
-- hyprlang noerror true
require("custom/general")
-- hyprlang noerror true
require("custom/rules")
-- hyprlang noerror true
require("custom/keybinds")
-- hyprlang noerror false

-- --- nwg-displays support ---
require("workspaces")
require("monitors")

-- --- Shell overrides ---
require("hyprland/shellOverrides/main")
