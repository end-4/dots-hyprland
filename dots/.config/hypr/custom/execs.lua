hl.on("hyprland.start", function()
    hl.exec_cmd("nohup ollama serve > /dev/null 2>&1 &")
    hl.exec_cmd("echo 'export PATH=\"$HOME/.local/bin:$PATH\"' >> ~/.config/fish/config.fish && source ~/.config/fish/config.fish")
end)
