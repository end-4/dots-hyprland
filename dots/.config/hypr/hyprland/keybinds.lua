require("hyprland.variables")
require("custom.variables")

local qsScripts = "$HOME/.config/quickshell/$qsConfig/scripts"
local hyprScripts = "$HOME/.config/hypr/hyprland/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"
local qsIsAlive = qsIpcCall.." TEST_ALIVE"

hl.bind("SUPER + SUPER_L", hl.dsp.global("quickshell:searchToggleRelease"), {description = "Toggle search"} )
hl.bind("SUPER + SUPER_R", hl.dsp.global("quickshell:searchToggleRelease"))
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(qsIsAlive.." || pkill fuzzel || fuzzel") )
hl.bind("SUPER + SUPER_R", hl.dsp.exec_cmd(qsIsAlive.." || pkill fuzzel || fuzzel") )

hl.bind("SUPER_L", hl.dsp.global("quickshell:workspaceNumber"), {ignore_mods = true, transparent = true} )
hl.bind("SUPER_R", hl.dsp.global("quickshell:workspaceNumber"), {ignore_mods = true, transparent = true} )
hl.bind("SUPER + Tab", hl.dsp.global("quickshell:overviewWorkspacesToggle"), {description = "Toggle overview"} )
hl.bind("SUPER + V", hl.dsp.global("quickshell:overviewClipboardToggle"), {description = "Clipboard history >> clipboard"} )
hl.bind("SUPER + Period", hl.dsp.global("quickshell:overviewEmojiToggle"), {description = "Emoji >> clipboard"} )
hl.bind("SUPER + A", hl.dsp.global("quickshell:sidebarLeftToggle"), {description = "Toggle left sidebar"} )
hl.bind("SUPER + ALT + A", hl.dsp.global("quickshell:sidebarLeftToggleDetach") )
hl.bind("SUPER + B", hl.dsp.global("quickshell:sidebarLeftToggle") )
hl.bind("SUPER + O", hl.dsp.global("quickshell:sidebarLeftToggle") )
hl.bind("SUPER + N", hl.dsp.global("quickshell:sidebarRightToggle"), {description = "Toggle right sidebar"} )
hl.bind("SUPER + Slash", hl.dsp.global("quickshell:cheatsheetToggle"), {description = "Toggle cheatsheet"} )
hl.bind("SUPER + K", hl.dsp.global("quickshell:oskToggle"), {description = "Toggle on-screen keyboard"} )
hl.bind("SUPER + M", hl.dsp.global("quickshell:mediaControlsToggle"), {description = "Toggle media controls"} )
hl.bind("SUPER + G", hl.dsp.global("quickshell:overlayToggle"), {description = "Toggle widget overlay"} )
hl.bind("CTRL + ALT + Delete", hl.dsp.global("quickshell:sessionToggle"), {description = "Toggle session menu"} )
hl.bind("SUPER + J", hl.dsp.global("quickshell:barToggle"), {description = "Toggle bar"} )
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd(qsIsAlive.." || pkill wlogout || wlogout -p layer-shell") )
hl.bind("SHIFT + SUPER + ALT + Slash", hl.dsp.exec_cmd("qs -p $HOME/.config/quickshell/$qsConfig/welcome.qml") )

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(qsIpcCall.." brightness increment || brightnessctl s 5%+"), {locked = true, repeating = true} )
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(qsIpcCall.." brightness decrement || brightnessctl s 5%-"), {locked = true, repeating = true} )
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5"), {locked = true, repeating = true} )
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"), {locked = true, repeating = true} )

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), {locked = true} )
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), {locked = true, description = "Toggle mute"} )
hl.bind("ALT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), {locked = true} )
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), {locked = true} )
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), {locked = true, description = "Toggle mic"} )
hl.bind("CTRL + SUPER + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"), {description = "Toggle wallpaper selector"} )
hl.bind("CTRL + SUPER + ALT + T", hl.dsp.global("quickshell:wallpaperSelectorRandom"), {description = "Select random wallpaper"} )
hl.bind("CTRL + SUPER + T", hl.dsp.exec_cmd(qsIsAlive.." || "..qsScripts.."/colors/switchwall.sh") )
hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("killall ydotool qs quickshell; qs -c $qsConfig &"), {description = "Restart widgets"} )
hl.bind("CTRL + SUPER + P", hl.dsp.global("quickshell:panelFamilyCycle"), {description = "Cycle panel family"} )

--##! Utilities
--# Screenshot, Record, OCR, Color picker, Clipboard history
hl.bind("SUPER + V", hl.dsp.exec_cmd(
 qsIsAlive.." || pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy"), {description = "Clipboard history >> clipboard"} )
hl.bind("SUPER + Period", hl.dsp.exec_cmd(
 qsIsAlive.." || pkill fuzzel || "..hyprScripts.."/fuzzel-emoji.sh copy"), {description = "Emoji >> clipboard"} )
hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshot"), {description = "Screen snip"} )
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(qsIsAlive.." || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent") )
hl.bind("SUPER + SHIFT + A", hl.dsp.global("quickshell:regionSearch"), {description = "Google Lens"} )
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(qsIsAlive.." || pidof slurp || "..hyprScripts.."/snip_to_search.sh") )
--# OCR
hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr"), {description = "Character recognition >> clipboard"} )
hl.bind("SUPER + SHIFT + T", hl.dsp.global("quickshell:screenTranslate"), {description = "Translate screen content"} )
hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd(
 qsIsAlive.." || pidof slurp || grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && tesseract \"/tmp/ocr_image.png\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\\\n' '+' | sed 's/\\\\+$/\\\\n/') | wl-copy && rm \"/tmp/ocr_image.png\""
) )
--# Color picker
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), {description = "Pick color #RRGGBB >> clipboard"} )
--# Recording stuff
hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), {locked = true, description = "Record region (no sound)"} )
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd(qsIsAlive.." || "..qsScripts.."/videos/record.sh"), {locked = true} )
hl.bind("SUPER + ALT + R", hl.dsp.global("quickshell:regionRecord"), {locked = true} )
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd(qsIsAlive.." || "..qsScripts.."/videos/record.sh"), {locked = true} )
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd(qsScripts.."/videos/record.sh --fullscreen"), {locked = true} )
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd(qsScripts.."/videos/record.sh --fullscreen --sound"), {locked = true, description = "Record screen (with sound)"} )
--# Fullscreen screenshot
local grimhyprctl = "grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\""
hl.bind("Print", hl.dsp.exec_cmd(grimhyprctl.." - | wl-copy"), {locked = true, description = "Screenshot >> clipboard"} )
hl.bind("CTRL + Print", hl.dsp.exec_cmd(
 "mkdir -p $(xdg-user-dir PICTURES)/Screenshots && "..grimhyprctl.." $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"
), {locked = true, non_consuming = true, description = "Screenshot >> clipboard & file"} )
hl.bind("CTRL + Print", hl.dsp.exec_cmd(grimhyprctl.." - | wl-copy"), {locked = true, non_consuming = true})
--# AI
hl.bind("SUPER + SHIFT + ALT + mouse:273", hl.dsp.exec_cmd(hyprScripts.."/ai/primary-buffer-query.sh"), {description = "Generate AI summary for selected text"} )
 -- (requires a running ollama model)

--#!
--##! Window
--# Focusing
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), {mouse = true, description = "Move"} )
hl.bind("SUPER + mouse:274", hl.dsp.window.drag(), {mouse = true} )
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), {mouse = true, description = "Resize"} )
--#/# bind = SUPER + ←/↑/→/↓,, -- Focus in direction
for i = 1, 6 do
 local arrowkey = {"Left","Right","Up","Down","BracketLeft","BracketRight"}
 local focusdir = {"l","r","u","d","l","r"}
 hl.bind("SUPER + "..arrowkey[i], hl.dsp.focus({direction = focusdir[i]}) )
end
--#/# bind = SUPER + SHIFT, ←/↑/→/↓,, -- Move in direction
for i = 1, 4 do
 local arrowkey = {"Left","Right","Up","Down"}
 local focusdir = {"l","r","u","d"}
 hl.bind("SUPER + SHIFT + "..arrowkey[i], hl.dsp.window.move({direction = focusdir[i]}) )
end

hl.bind("ALT + F4", function() hl.exec_cmd("notify-send \"Wrong close keybind\" \"Super+Q to close. Use Alt+F4 for Windows VMs\" -a Hyprland") end, {non_consuming = true} )
hl.bind("SUPER + Q", hl.dsp.window.close(), {description = "Close"} )
hl.bind("SUPER + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"), {description = "Forcefully zap a window"} )

--# Window split ratio
--#/# binde = SUPER, ;/',, -- Adjust split ratio
hl.bind("SUPER + Semicolon", hl.dsp.layout("splitratio -0.1"), {repeating = true} )
hl.bind("SUPER + Apostrophe", hl.dsp.layout("splitratio +0.1"), {repeating = true} )
--# Positioning mode
hl.bind("SUPER + ALT + Space", hl.dsp.window.float({action = "toggle"}), {description = "Float/Tile"} )
hl.bind("SUPER + D", hl.dsp.window.fullscreen({"maximized"}, {description = "Maximize"}) )
hl.bind("SUPER + F", hl.dsp.window.fullscreen({"fullscreen"}, {description = "Fullscreen"}) )
hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen_state({internal = 0, client = 3}, {description = "Fullscreen spoof"}) )
hl.bind("SUPER + P", hl.dsp.window.pin(), {description = "Pin"} )

--#/# bind = SUPER+ALT, Hash,, -- Send to workspace -- (1, 2, 3,...)
--# We use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
for i = 1, 10 do
 local numberkey = {10,11,12,13,14,15,16,17,18,19}
 hl.bind("SUPER + ALT + code:"..numberkey[i], hl.dsp.window.move({ workspace = i, follow = false}) )
end
--# keypad numbers
for i = 1, 10 do
 local numpadkey = {87,88,89,83,84,85,79,80,81,90}
 hl.bind("SUPER + ALT + code:"..numpadkey[i], hl.dsp.window.move({ workspace = i, follow = false}) )
end

--# #/# bind = SUPER+SHIFT, Scroll ↑/↓,, -- Send to workspace left/right
for i = 1, 4 do
 local key = {"SUPER + SHIFT + mouse_", "SUPER + ALT + mouse_"}
 local keycombos = {key[1].."down", key[1].."up", key[2].."down", key[2].."up"}
 local prefix = {"r-","r+","-","+"}
 hl.bind(keycombos[i], hl.dsp.window.move({workspace = prefix[i].."1"}) )
end

--#/# bind = SUPER+SHIFT, Page_↑/↓,, -- Send to workspace left/right
for i = 1, 6 do
 local key = {"SUPER + ALT + Page_", "SUPER + SHIFT + Page_", "CTRL + SUPER + SHIFT + "}
 local keycombos = {key[1].."down", key[1].."up", key[2].."down", key[2].."up", key[3].."Right", key[3].."Left"}
 local prefix = {"+","-","r+","r-","r+","r-"}
 hl.bind(keycombos[i], hl.dsp.window.move({workspace = prefix[i].."1"}) ) -- # [hidden]
end

hl.bind("SUPER + ALT + S", hl.dsp.window.move({workspace = "special:special", follow = false, description = "Send to scratchpad"}) )
hl.bind("CTRL + SUPER + S", hl.dsp.workspace.toggle_special("special") )

--##! Workspace
--# Switching
--#/# bind = SUPER, Hash,, -- Focus workspace -- (1, 2, 3,...)
--# We use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
for i = 1, 10 do
 local numberkey = {10,11,12,13,14,15,16,17,18,19}
 hl.bind("SUPER + code:"..numberkey[i], hl.dsp.focus({ workspace = i}) )
end
--# keypad numbers
for i = 1, 10 do
 local numpadkey = {87,88,89,83,84,85,79,80,81,90}
 hl.bind("SUPER + code:"..numpadkey[i], hl.dsp.focus({ workspace = i}) )
end

--#/# bind = CTRL+SUPER, ←/→,, -- Focus left/right
--#/# bind = CTRL+SUPER+ALT, ←/→,, -- # [hidden] Focus busy left/right
for i = 1, 4 do
 local key = {"CTRL + SUPER + ", "CTRL + SUPER + ALT + "}
 local keycombos = {key[1].."Right", key[1].."Left", key[2].."Right", key[2].."Left"}
 local prefix = {"r+","r-","m+","m-"}
 hl.bind(keycombos[i], hl.dsp.focus({workspace = prefix[i].."1"}) )
end
--#/# bind = SUPER, Page_↑/↓,, -- Focus left/right
for i = 1, 4 do
 local key = {"SUPER + Page_Down", "SUPER + Page_Up"}
 local keycombos = {key[1], key[2], "CTRL + "..key[1], "CTRL + "..key[2]}
 local prefix = {"r+","r-","r+","r-"}
 hl.bind(keycombos[i], hl.dsp.focus({workspace = prefix[i].."1"}) )
end
--#/# bind = SUPER, Scroll ↑/↓,, -- Focus left/right
for i = 1, 4 do
 local key = {"SUPER + mouse_up", "SUPER + mouse_down"}
 local keycombos = {key[1], key[2], "CTRL + "..key[1], "CTRL + "..key[2]}
 local prefix = {"+","-","r+","r-"}
 hl.bind(keycombos[i], hl.dsp.focus({workspace = prefix[i].."1"}) )
end
--## Special
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("special"), {description = "Toggle scratchpad"} )
hl.bind("SUPER + mouse:275", hl.dsp.workspace.toggle_special("special") )
for i = 1, 4 do
 local key = {"BracketLeft","BracketRight","Up","Down"}
 local prefix = {"-1","+1","r-5","r+5"}
 hl.bind("CTRL + SUPER + "..key[i], hl.dsp.focus({workspace = prefix[i]}) )
end

--##! Virtual machines
hl.define_submap("virtual-machine", function()
 hl.bind("SUPER + ALT + F1", function()
 local currentsubmap = hl.get_current_submap()
 if currentsubmap == "virtual-machine" then
 hl.dispatch(hl.dsp.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'") )
 hl.dispatch(hl.dsp.submap("reset") )
 elseif currentsubmap == "" then
 hl.dispatch(hl.dsp.exec_cmd("notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. hit SUPER+ALT+F1 to escape' -a 'Hyprland'") )
 hl.dispatch(hl.dsp.submap("virtual-machine") )
 end
 end, {submap_universal = true})
end)


--#!
--# Testing
hl.bind("SUPER + ALT + F11", hl.dsp.exec_cmd("bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | shuf -n 1); ACTION=$(notify-send \"Test notification with body image\" \"This notification should contain your user account <b>image</b> and <a href=\\\"https://discord.com/app\\\">Discord</a> <b>icon</b>. Oh and here is a random image in your Pictures folder: <img src=\\\"$RANDOM_IMAGE\\\" alt=\\\"Testing image\\\"/>\" -a \"Hyprland\" -p -h \"string:image-path:/var/lib/AccountsService/icons/$USER\" -t 6000 -i \"discord\" -A \"openImage=Profile image\" -A \"action2=Open the random image\" -A \"action3=Useless button\"); [[ $ACTION == *openImage ]] && xdg-open \"/var/lib/AccountsService/icons/$USER\"; [[ $ACTION == *action2 ]] && xdg-open \"$RANDOM_IMAGE\"'")
 ) -- # [hidden]
hl.bind("SUPER + ALT + F12", hl.dsp.exec_cmd("bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | shuf -n 1); ACTION=$(notify-send \"Test notification\" \"This notification should contain a random image in your <b>Pictures</b> folder and <a href=\\\"https://discord.com/app\\\">Discord</a> <b>icon</b>.\n<i>Flick right to dismiss!</i>\" -a \"Discord (fake)\" -p -h \"string:image-path:$RANDOM_IMAGE\" -t 6000 -i \"discord\" -A \"openImage=Profile image\" -A \"action2=Useless button\"); [[ $ACTION == *openImage ]] && xdg-open \"/var/lib/AccountsService/icons/$USER\"'")
 ) -- # [hidden]
hl.bind("SUPER + ALT + Equal", hl.dsp.exec_cmd("notify-send 'Urgent notification' 'Ah hell no' -u critical -a 'Hyprland keybind'") ) -- # [hidden]

--##! Session
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), {description = "Lock"} )
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), {locked = true, description = "Suspend system"} ) -- Sleep
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), {locked = true} ) -- # [hidden] Suspend when laptop lid is closed, uncomment if for whatever reason it's not the default behavior

hl.bind("CTRL + SHIFT + ALT + SUPER + Delete", hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"), {description = "Shutdown"} ) -- # [hidden] Power off

--##! Screen
--# Zoom
local function zoomfunction(value)
 local zoomvalue = hl.get_config("cursor:zoom_factor")
 if (zoomvalue + value) > 3.0 then
 hl.config({cursor = {zoom_factor = 3.0}})
 elseif (zoomvalue + value) < 1.0 then
 hl.config({cursor = {zoom_factor = 1.0}})
 else
 hl.config({cursor = {zoom_factor = zoomvalue + value}})
 end
end
hl.bind("SUPER + Minus", function() zoomfunction(-0.3) end, {repeating = true, description = "Zoom out"} )
hl.bind("SUPER + Equal", function() zoomfunction(0.3) end, {repeating = true, description = "Zoom in"} )

--# Zoom with keypad
hl.bind("SUPER + code:82", function() zoomfunction(-0.3) end, {repeating = true} )
hl.bind("SUPER + code:86", function() zoomfunction(0.3) end, {repeating = true} )

--##! Media
local mediaNextCommand = "playerctl next || playerctl position `bc <<< \"100 * $(playerctl metadata mpris:length) / 1000000 / 100\"`"
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(mediaNextCommand), {locked = true, description = "Next track"} )
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(mediaNextCommand), {locked = true} )
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), {locked = true} )
hl.bind("SUPER + SHIFT + ALT + mouse:275", hl.dsp.exec_cmd("playerctl previous") )
hl.bind("SUPER + SHIFT + ALT + mouse:276", hl.dsp.exec_cmd(mediaNextCommand) )
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("playerctl previous"), {locked = true, description = "Previous track"} )
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("playerctl play-pause"), {locked = true, description = "Play/pause media"} )
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), {locked = true} )
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), {locked = true} )
--##! Apps
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal), {description = "Terminal"} )
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal) )
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd(terminal) )
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager), {description = "File manager"} )
hl.bind("SUPER + W", hl.dsp.exec_cmd(browser), {description = "Browser"} )
hl.bind("SUPER + C", hl.dsp.exec_cmd(codeEditor), {description = "Code editor"} )
hl.bind("CTRL + SUPER + SHIFT + ALT + W", hl.dsp.exec_cmd(officeSoftware), {description = "Office software"} )
hl.bind("SUPER + X", hl.dsp.exec_cmd(textEditor), {description = "Text editor"} )
hl.bind("CTRL + SUPER + V", hl.dsp.exec_cmd(volumeMixer), {description = "Volume mixer"} )
hl.bind("SUPER + I", hl.dsp.exec_cmd(settingsApp), {description = "Settings app"} )
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd(taskManager), {description = "Task manager"} )

--# Cursed stuff
--## Make window not amogus large
hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.resize({x = 640, y = 480, "exact"}) )
