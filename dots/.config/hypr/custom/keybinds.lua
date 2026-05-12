--! User
hl.bind("CTRL + SUPER", "Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"), {description = "Edit shell config"})
hl.bind("CTRL + SUPER + ALT", "Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit extra keybinds"})
hl.bind("SUPER", "W", hl.dsp.global("quickshell:panelFamilyCycle"), {description = "Cycle panel family"})
hl.bind("SUPER", "B", hl.dsp.exec_cmd(
    "$HOME/.config/hypr/hyprland/scripts/launch_first_available.sh"
    .. " \"google-chrome-stable\" \"zen-browser\" \"firefox\" \"brave\""
    .. " \"chromium\" \"microsoft-edge-stable\" \"opera\" \"librewolf\""
), {description = "Browser"})
hl.bind("CTRL + SUPER", "S", hl.dsp.togglespecialworkspace(""))

--! Apps
hl.bind("SUPER", "Space", hl.dsp.exec_cmd("ollama launch claude --model minimax-m2.7:cloud"))

--! Power
hl.bind("", "XF86Launch4", hl.dsp.exec_cmd("qs ipc call powerProfile cycle"), {description = "Cycle power profile (Fn+Q)"})hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
