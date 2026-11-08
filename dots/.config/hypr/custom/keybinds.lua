hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Toggle end4-pC Settings Overlay
hl.bind("SUPER + escape", hl.dsp.global("quickshell:settingsToggle"), {description = "Toggle settings"})

-- Switch to virtual workspaces 1-10 with Super + top number row (1, 2, 3, 4, 5, 6, 7, 8, 9, 0)
for i = 1, 10 do
    local key = i % 10
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }), { description = "Workspace: Switch to " .. i })
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = "Window: Move to workspace " .. i })
end

-- Cycle through open windows with Alt + Tab
hl.bind("ALT + Tab", hl.dsp.window.cycle_next(), { description = "Window: Cycle next" })

-- Windows-style Display Switcher (Win + P)
hl.unbind("SUPER + P")
hl.bind("SUPER + P", hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/project-display-toggle.sh"), { description = "Displays: Switch display mode (Win+P)" })
hl.bind("SUPER + ALT + P", hl.dsp.window.pin(), { description = "Window: Pin" })

-- Clamshell Mode: Smart laptop lid handling (docked with HDMI -> stay awake on external; undocked -> suspend)
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hypr-monitors lid-close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hypr-monitors lid-open"), { locked = true })


