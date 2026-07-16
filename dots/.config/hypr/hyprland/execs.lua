-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function()
    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")

    -- Instant non-blocking check for active nvidia driver
    local is_nvidia = false
    local nv_check = io.open("/proc/driver/nvidia/version", "r")
    if nv_check then
        is_nvidia = true
        nv_check:close()
    end

    local qs_cmd = "qs -c $qsConfig"
    if is_nvidia then
        qs_cmd =
        "QS_FORCE_VULKAN=1 QT_QUICK_BACKEND=vulkan VK_DRIVER_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json " ..
        qs_cmd
    end
    hl.exec_cmd(qs_cmd)

    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

    -- Core components (authentication, lock screen, notification daemon)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

    -- Audio
    hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard: history
    --hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd(
    "wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")
    hl.exec_cmd(
    "wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
