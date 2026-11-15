-- Custom autostart commands
hl.on("hyprland.start", function ()
    hl.exec_cmd("hypr-monitors daemon &")
end)
