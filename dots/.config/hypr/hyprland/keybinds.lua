-- Left the hashes that I think you use in your quickshell and scripts in hope it doesn't break the cheatsheat
-- Lines ending with `# [hidden]` won't be shown on cheatsheet
-- Lines starting with #! are section headings

-- DO NOT REMOVE THIS EXEC OR YOU WON'T BE ABLE TO USE ANY KEYBIND
hl.dsp.exec_cmd("hyprctl dispatch submap global")

--#!
--##! Shell
--# These absolutely need to be on top, or they won't work consistently
-- example: hl.bind(keys, dispatcher, {flag1 = true, flag2 = true})
hl.bind("SUPER + SUPER_L",                      hl.dsp.global("quickshell:searchToggleRelease"),                                                                        {ignore_mods = true, description = "Toggle search"}             ) -- Toggle search
hl.bind("SUPER + SUPER_R",                      hl.dsp.global("quickshell:searchToggleRelease"),                                                                        {ignore_mods = true, description = "Toggle search"}             ) -- # [hidden] Toggle search
hl.bind("SUPER + SUPER_L",                      hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || fuzzel")                                                                                                        ) -- # [hidden] Launcher (fallback)
hl.bind("SUPER + SUPER_R",                      hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || fuzzel")                                                                                                        ) -- # [hidden] Launcher (fallback)
-- This is required for catchall to work
hl.define_submap("global", function() -- can't seem to get it to work when adding SUPER
    hl.bind("catchall",                     hl.dsp.global("quickshell:searchToggleReleaseInterrupt"),                                                                   {ignore_mods = true, transparent = true, non_consuming = true}  ) -- # [hidden]
end)
hl.bind("CTRL + SUPER_L",                       hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]
hl.bind("CTRL + SUPER_R",                       hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]
hl.bind("SUPER + mouse:272",                    hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]
hl.bind("SUPER + mouse:273",                    hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]
hl.bind("SUPER + mouse:274",                    hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]
hl.bind("SUPER + mouse:275",                    hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]
hl.bind("SUPER + mouse:276",                    hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]
hl.bind("SUPER + mouse:277",                    hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]
hl.bind("SUPER + mouse_up",                     hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]
hl.bind("SUPER + mouse_down",                   hl.dsp.global("quickshell:searchToggleReleaseInterrupt")                                                                                                                                ) -- # [hidden]

hl.bind(" + SUPER_L",                           hl.dsp.global("quickshell:workspaceNumber"),                                                                            {ignore_mods = true, transparent = true}                        ) -- # [hidden]
hl.bind(" + SUPER_R",                           hl.dsp.global("quickshell:workspaceNumber"),                                                                            {ignore_mods = true, transparent = true}                        ) -- # [hidden]
hl.bind("SUPER + Tab",                          hl.dsp.global("quickshell:overviewWorkspacesToggle")                                                                                                                                    ) -- Toggle overview
hl.bind("SUPER + V",                            hl.dsp.global("quickshell:overviewClipboardToggle"),                                                                    {description = "Clipboard history >> clipboard"}                ) -- Clipboard history >> clipboard
hl.bind("SUPER + Period",                       hl.dsp.global("quickshell:overviewEmojiToggle"),                                                                        {description = "Emoji >> clipboard"}                            ) -- Emoji >> clipboard
hl.bind("SUPER + A",                            hl.dsp.global("quickshell:sidebarLeftToggle")                                                                                                                                           ) -- Toggle left sidebar
hl.bind("SUPER + ALT + A",                      hl.dsp.global("quickshell:sidebarLeftToggleDetach")                                                                                                                                     ) -- # [hidden]
hl.bind("SUPER + B",                            hl.dsp.global("quickshell:sidebarLeftToggle")                                                                                                                                           ) -- # [hidden]
hl.bind("SUPER + O",                            hl.dsp.global("quickshell:sidebarLeftToggle")                                                                                                                                           ) -- # [hidden]
hl.bind("SUPER + N",                            hl.dsp.global("quickshell:sidebarRightToggle"),                                                                         {description = "Toggle right sidebar"}                          ) -- Toggle right sidebar
hl.bind("SUPER + Slash",                        hl.dsp.global("quickshell:cheatsheetToggle"),                                                                           {description = "Toggle cheatsheet"}                             ) -- Toggle cheatsheet
hl.bind("SUPER + K",                            hl.dsp.global("quickshell:oskToggle"),                                                                                  {description = "Toggle on-screen keyboard"}                     ) -- Toggle on-screen keyboard
hl.bind("SUPER + M",                            hl.dsp.global("quickshell:mediaControlsToggle"),                                                                        {description = "Toggle media controls"}                         ) -- Toggle media controls
hl.bind("SUPER + G",                            hl.dsp.global("quickshell:overlayToggle")                                                                                                                                               ) -- Toggle overlay
hl.bind("CTRL + ALT + Delete",                  hl.dsp.global("quickshell:sessionToggle"),                                                                              {description = "Toggle session menu"}                           ) -- Toggle session menu
hl.bind("SUPER + J",                            hl.dsp.global("quickshell:barToggle"),                                                                                  {description = "Toggle bar"}                                    ) -- Toggle bar
hl.bind("CTRL + ALT + Delete",                  hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || pkill wlogout || wlogout -p layer-shell")                                                                                       ) -- # [hidden] Session menu (fallback)
hl.bind("SHIFT + SUPER + ALT + Slash",          hl.dsp.exec_cmd("qs -p ~/.config/quickshell/$qsConfig/welcome.qml")                                                                                                                     ) -- # [hidden] Launch welcome app

hl.bind("XF86MonBrightnessUp",                  hl.dsp.exec_cmd("qs -c $qsConfig ipc call brightness increment || brightnessctl s 5%+"),                                {locked = true, repeating = true}                               ) -- # [hidden]
hl.bind("XF86MonBrightnessDown",                hl.dsp.exec_cmd("qs -c $qsConfig ipc call brightness decrement || brightnessctl s 5%-"),                                {locked = true, repeating = true}                               ) -- # [hidden]
hl.bind("XF86AudioRaiseVolume",                 hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5"),                                                    {locked = true, repeating = true}                               ) -- # [hidden]
hl.bind("XF86AudioLowerVolume",                 hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),                                                           {locked = true, repeating = true}                               ) -- # [hidden]

hl.bind("XF86AudioMute",                        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"),                                                                {locked = true}                                                 ) -- # [hidden]
hl.bind("SUPER + SHIFT + M",                    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"),                                                                {locked = true, description = "Toggle mute"}                    ) -- # [hidden]
hl.bind("ALT + XF86AudioMute",                  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"),                                                              {locked = true}                                                 ) -- # [hidden]
hl.bind("XF86AudioMicMute",                     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"),                                                              {locked = true}                                                 ) -- # [hidden]
hl.bind("SUPER + ALT + M",                      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"),                                                              {locked = true, description = "Toggle mic"}                     ) -- # [hidden]
hl.bind("CTRL + SUPER + T",                     hl.dsp.global("quickshell:wallpaperSelectorToggle"),                                                                    {description = "Toggle wallpaper selector"}                     ) -- Wallpaper selector
hl.bind("CTRL + SUPER + ALT + T",               hl.dsp.global("quickshell:wallpaperSelectorRandom"),                                                                    {description = "Select random wallpaper"}                       ) -- Random wallpaper
hl.bind("CTRL + SUPER + T",                     hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/quickshell/$qsConfig/scripts/colors/switchwall.sh"),  {description = "Change wallpaper"}                              ) -- # [hidden] Change wallpaper (fallback)
hl.bind("CTRL + SUPER + R",                     hl.dsp.exec_cmd("killall ydotool qs quickshell; qs -c $qsConfig &")                                                                                                                     ) -- Restart widgets
hl.bind("CTRL + SUPER + P",                     hl.dsp.global("quickshell:panelFamilyCycle")                                                                                                                                            ) -- Cycle panel family

--##! Utilities
--# Screenshot, Record, OCR, Color picker, Clipboard history
hl.bind("SUPER + V",                            hl.dsp.exec_cmd(
    "qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy"),                              {description = "Copy clipboard history entry"}                  ) -- # [hidden] Clipboard history >> clipboard (fallback)
hl.bind("SUPER + Period",                       hl.dsp.exec_cmd(
    "qs -c $qsConfig ipc call TEST_ALIVE || pkill fuzzel || ~/.config/hypr/hyprland/scripts/fuzzel-emoji.sh copy"),                                                     {description = "Copy an emoji"}                                 ) -- # [hidden] Emoji >> clipboard (fallback)
hl.bind("SUPER + SHIFT + S",                    hl.dsp.global("quickshell:regionScreenshot")                                                                                                                                            ) -- Screen snip
hl.bind("SUPER + SHIFT + S",                    hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent")                                                      ) -- # [hidden] Screen snip (fallback)
hl.bind("SUPER + SHIFT + A",                    hl.dsp.global("quickshell:regionSearch")                                                                                                                                                ) -- Google Lens
hl.bind("SUPER + SHIFT + A",                    hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || ~/.config/hypr/hyprland/scripts/snip_to_search.sh")                                                              ) -- # [hidden] Google Lens (fallback)
--# OCR
hl.bind("SUPER + SHIFT + X",                    hl.dsp.global("quickshell:regionOcr")                                                                                                                                                   ) -- Character recognition >> clipboard
hl.bind("SUPER + SHIFT + T",                    hl.dsp.global("quickshell:screenTranslate")                                                                                                                                             ) -- Translate screen content
hl.bind("SUPER + SHIFT + X",                    hl.dsp.exec_cmd(
    "qs -c $qsConfig ipc call TEST_ALIVE || pidof slurp || grim -g '$(slurp $SLURP_ARGS)' '/tmp/ocr_image.png && tesseract' '/tmp/ocr_image.png' stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\n' '+' | sed 's/\\+$/\\n/') | wl-copy && rm '/tmp/ocr_image.png'"
)                                                                                                                                                                                                                                       ) -- # [hidden]
--# Color picker
hl.bind("SUPER + SHIFT + C",                    hl.dsp.exec_cmd("hyprpicker -a"),                                                                                       {description = "Color picker"}                                  ) -- Pick color (Hex) >> clipboard
--# Recording stuff
hl.bind("SUPER + SHIFT + R",                    hl.dsp.global("quickshell:regionRecord"),                                                                               {locked = true}                                                 ) -- Record region (no sound)
hl.bind("SUPER + SHIFT + R",                    hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/quickshell/$qsConfigscripts/videos/record.sh"),       {locked = true}                                                 ) -- # [hidden] Record region (no sound) (fallback)
hl.bind("SUPER + ALT + R",                      hl.dsp.global("quickshell:regionRecord"),                                                                               {locked = true}                                                 ) -- # [hidden] Record region (no sound)
hl.bind("SUPER + ALT + R",                      hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/quickshell/$qsConfigscripts/videos/record.sh"),       {locked = true}                                                 ) -- # [hidden] Record region (no sound) (fallback)
hl.bind("CTRL + ALT + R",                       hl.dsp.exec_cmd("~/.config/quickshell/$qsConfig/scripts/videos/record.sh --fullscreen"),                                {locked = true}                                                 ) -- # [hidden] Record screen (no sound)
hl.bind("SUPER + SHIFT + ALT + R",              hl.dsp.exec_cmd("~/.config/quickshell/$qsConfig/scripts/videos/record.sh --fullscreen --sound"),                        {locked = true}                                                 ) -- Record screen (with sound)
--# Fullscreen screenshot
hl.bind("Print",                                hl.dsp.exec_cmd("grim -o '$(hyprctl activeworkspace -j | jq -r '.monitor')' - | wl-copy"),                              {locked = true}                                                 ) -- Screenshot >> clipboard
hl.bind("CTRL + Print",                         hl.dsp.exec_cmd(
    "mkdir -p $(xdg-user-dir PICTURES)/Screenshots && grim -o '$(hyprctl activeworkspace -j | jq -r '.monitor')' $(xdg-user-dir PICTURES)/Screenshots/Screenshot_'$(date '+%Y-%m-%d_%H.%M.%S')'.png"
),                                                                                                                                                                      {locked = true, non_consuming = true}                           ) -- Screenshot >> clipboard & file
hl.bind("CTRL + Print",                         hl.dsp.exec_cmd("grim -o '$(hyprctl activeworkspace -j | jq -r '.monitor')' - | wl-copy"),                              {locked = true, non_consuming = true}                           ) -- # [hidden] Screenshot >> clipboard & file (clipboard)
--# AI
hl.bind("SUPER + SHIFT + ALT + mouse:273",      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/ai/primary-buffer-query.sh"),                                          {description = "Generate AI summary for selected text"}         ) -- # [hidden] AI summary for selected text
                                                                                                                                                                                                                                          --       (requires a running ollama model)

--#!
--##! Window
--# Focusing
hl.bind("SUPER + mouse:272",                    hl.dsp.window.drag(),                                                                                                   {mouse = true}                                                  ) -- Move
hl.bind("SUPER + mouse:274",                    hl.dsp.window.drag(),                                                                                                   {mouse = true}                                                  ) -- # [hidden]
hl.bind("SUPER + mouse:273",                    hl.dsp.window.resize(),                                                                                                 {mouse = true}                                                  ) -- Resize
--#/# bind = SUPER + ←/↑/→/↓,, -- Focus in direction
hl.bind("SUPER + Left",                         hl.dsp.focus({direction = "l"})                                                                                                                                                         ) -- # [hidden]
hl.bind("SUPER + Right",                        hl.dsp.focus({direction = "r"})                                                                                                                                                         ) -- # [hidden]
hl.bind("SUPER + Up",                           hl.dsp.focus({direction = "u"})                                                                                                                                                         ) -- # [hidden]
hl.bind("SUPER + Down",                         hl.dsp.focus({direction = "d"})                                                                                                                                                         ) -- # [hidden]
hl.bind("SUPER + BracketLeft",                  hl.dsp.focus({direction = "l"})                                                                                                                                                         ) -- # [hidden]
hl.bind("SUPER + BracketRight",                 hl.dsp.focus({direction = "r"})                                                                                                                                                         ) -- # [hidden]
--#/# bind = SUPER + SHIFT, ←/↑/→/↓,, -- Move in direction
hl.bind("SUPER + SHIFT + Left",                 hl.dsp.window.move({direction = "l"})                                                                                                                                                   ) -- # [hidden]
hl.bind("SUPER + SHIFT + Right",                hl.dsp.window.move({direction = "r"})                                                                                                                                                   ) -- # [hidden]
hl.bind("SUPER + SHIFT + Up",                   hl.dsp.window.move({direction = "u"})                                                                                                                                                   ) -- # [hidden]
hl.bind("SUPER + SHIFT + Down",                 hl.dsp.window.move({direction = "d"})                                                                                                                                                   ) -- # [hidden]
hl.bind("ALT + F4",                             hl.dsp.window.close()                                                                                                                                                                   ) -- # [hidden] Close (Windows)
hl.bind("SUPER + Q",                            hl.dsp.window.close()                                                                                                                                                                   ) -- Close
hl.bind("SUPER + SHIFT + ALT + Q",              hl.dsp.exec_cmd("hyprctl kill")                                                                                                                                                         ) -- Forcefully zap a window


--# Window split ratio
--#/# binde = SUPER, ;/',, -- Adjust split ratio
hl.bind("SUPER + Semicolon",                    hl.dsp.layout("splitratio -0.1"),                                                                                       {repeating = true}                                              ) -- # [hidden]
hl.bind("SUPER + Apostrophe",                   hl.dsp.layout("splitratio +0.1"),                                                                                       {repeating = true}                                              ) -- # [hidden]
--# Positioning mode
hl.bind("SUPER + ALT + Space",                  hl.dsp.window.float({action = "toggle"})                                                                                                                                                ) -- Float/Tile
hl.bind("SUPER + D",                            hl.dsp.window.fullscreen({maximized})                                                                                                                                                   ) -- Maximize
hl.bind("SUPER + F",                            hl.dsp.window.fullscreen({fullscreen})                                                                                                                                                  ) -- Fullscreen
hl.bind("SUPER + ALT + F",                      hl.dsp.window.fullscreen_state({internal = 0, client = 3})                                                                                                                              ) -- Fullscreen spoof
hl.bind("SUPER + P",                            hl.dsp.window.pin()                                                                                                                                                                     ) -- Pin

--#/# bind = SUPER+ALT, Hash,, -- Send to workspace -- (1, 2, 3,...)
--# We use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
hl.bind("SUPER + ALT + code:10",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 1")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:11",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 2")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:12",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 3")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:13",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 4")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:14",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 5")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:15",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 6")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:16",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 7")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:17",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 8")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:18",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 9")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:19",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 10")                                                                                         ) -- # [hidden]
--# keypad numbers
hl.bind("SUPER + ALT + code:87",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 1")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:88",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 2")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:89",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 3")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:83",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 4")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:84",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 5")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:85",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 6")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:79",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 7")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:80",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 8")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:81",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 9")                                                                                          ) -- # [hidden]
hl.bind("SUPER + ALT + code:90",                hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent 10")                                                                                         ) -- # [hidden]

--# #/# bind = SUPER+SHIFT, Scroll ↑/↓,, -- Send to workspace left/right
hl.bind("SUPER + SHIFT + mouse_down",           hl.dsp.window.move({workspace = "r-1"})                                                                                                                                                 ) -- # [hidden]
hl.bind("SUPER + SHIFT + mouse_up",             hl.dsp.window.move({workspace = "r+1"})                                                                                                                                                 ) -- # [hidden]
hl.bind("SUPER + ALT + mouse_down",             hl.dsp.window.move({workspace = "-1"})                                                                                                                                                  ) -- # [hidden]
hl.bind("SUPER + ALT + mouse_up",               hl.dsp.window.move({workspace = "+1"})                                                                                                                                                  ) -- # [hidden]

--#/# bind = SUPER+SHIFT, Page_↑/↓,, -- Send to workspace left/right
hl.bind("SUPER + ALT + Page_down",              hl.dsp.window.move({workspace = "+1"})                                                                                                                                                  ) -- # [hidden]
hl.bind("SUPER + ALT + Page_up",                hl.dsp.window.move({workspace = "-1"})                                                                                                                                                  ) -- # [hidden]
hl.bind("SUPER + SHIFT + Page_down",            hl.dsp.window.move({workspace = "r+1"})                                                                                                                                                 ) -- # [hidden]
hl.bind("SUPER + SHIFT + Page_up",              hl.dsp.window.move({workspace = "r-1"})                                                                                                                                                 ) -- # [hidden]
hl.bind("CTRL + SUPER + SHIFT + Right",         hl.dsp.window.move({workspace = "r+1"})                                                                                                                                                 ) -- # [hidden]
hl.bind("CTRL + SUPER + SHIFT + Left",          hl.dsp.window.move({workspace = "r-1"})                                                                                                                                                 ) -- # [hidden]

hl.bind("SUPER + ALT + S",                      hl.dsp.window.move({workspace = "special:special", silent = true})                                                                                                                      ) -- Send to scratchpad

hl.bind("CTRL + SUPER + S",                     hl.dsp.workspace.toggle_special("special")                                                                                                                                              ) -- # [hidden]

--##! Workspace
--# Switching
--#/# bind = SUPER, Hash,, -- Focus workspace -- (1, 2, 3,...)
--# We use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
hl.bind("SUPER + code:10",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 1")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:11",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 2")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:12",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 3")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:13",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 4")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:14",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 5")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:15",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 6")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:16",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 7")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:17",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 8")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:18",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 9")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:19",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 10")                                                                                                     ) -- # [hidden]
--# keypad numbers
hl.bind("SUPER + code:87",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 1")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:88",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 2")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:89",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 3")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:83",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 4")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:84",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 5")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:85",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 6")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:79",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 7")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:80",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 8")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:81",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 9")                                                                                                      ) -- # [hidden]
hl.bind("SUPER + code:90",                      hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh workspace 10")                                                                                                     ) -- # [hidden]

--#/# bind = CTRL+SUPER, ←/→,, -- Focus left/right
hl.bind("CTRL + SUPER + Right",                 hl.dsp.focus({workspace = "r+1"})                                                                                                                                                       ) -- # [hidden]
hl.bind("CTRL + SUPER + Left",                  hl.dsp.focus({workspace = "r-1"})                                                                                                                                                       ) -- # [hidden]
--#/# bind = CTRL+SUPER+ALT, ←/→,, -- # [hidden] Focus busy left/right
hl.bind("CTRL + SUPER + ALT + Right",           hl.dsp.focus({workspace = "m+1"})                                                                                                                                                       ) -- # [hidden]
hl.bind("CTRL + SUPER + ALT + Left",            hl.dsp.focus({workspace = "m-1"})                                                                                                                                                       ) -- # [hidden]
--#/# bind = SUPER, Page_↑/↓,, -- Focus left/right
hl.bind("SUPER + Page_Down",                    hl.dsp.focus({workspace = "+1"})                                                                                                                                                        ) -- # [hidden]
hl.bind("SUPER + Page_Up",                      hl.dsp.focus({workspace = "-1"})                                                                                                                                                        ) -- # [hidden]
hl.bind("CTRL + SUPER + Page_Down",             hl.dsp.focus({workspace = "r+1"})                                                                                                                                                       ) -- # [hidden]
hl.bind("CTRL + SUPER + Page_Up",               hl.dsp.focus({workspace = "r-1"})                                                                                                                                                       ) -- # [hidden]
--#/# bind = SUPER, Scroll ↑/↓,, -- Focus left/right
hl.bind("SUPER + mouse_up",                     hl.dsp.focus({workspace = "+1"})                                                                                                                                                        ) -- # [hidden]
hl.bind("SUPER + mouse_down",                   hl.dsp.focus({workspace = "-1"})                                                                                                                                                        ) -- # [hidden]
hl.bind("CTRL + SUPER + mouse_up",              hl.dsp.focus({workspace = "r+1"})                                                                                                                                                       ) -- # [hidden]
hl.bind("CTRL + SUPER + mouse_down",            hl.dsp.focus({workspace = "r-1"})                                                                                                                                                       ) -- # [hidden]
--## Special
hl.bind("SUPER + S",                            hl.dsp.workspace.toggle_special("special")                                                                                                                                              ) -- Toggle scratchpad
hl.bind("SUPER + mouse:275",                    hl.dsp.workspace.toggle_special("special")                                                                                                                                              ) -- # [hidden]
hl.bind("CTRL + SUPER + BracketLeft",           hl.dsp.window.move({workspace = "-1"})                                                                                                                                                  ) -- # [hidden]
hl.bind("CTRL + SUPER + BracketRight",          hl.dsp.window.move({workspace = "+1"})                                                                                                                                                  ) -- # [hidden]
hl.bind("CTRL + SUPER + Up",                    hl.dsp.window.move({workspace = "r-5"})                                                                                                                                                 ) -- # [hidden]
hl.bind("CTRL + SUPER + Down",                  hl.dsp.window.move({workspace = "r+5"})                                                                                                                                                 ) -- # [hidden]

--##! Virtual machines
hl.bind("SUPER + ALT + F1",                     hl.dsp.exec_cmd("notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. Hit SUPER+ALT+F1 to escape' -a 'Hyprland' && hyprctl dispatch submap virtual-machine")                ) -- Disable keybinds
hl.define_submap("virtual-machine", function() end)
hl.bind("SUPER + ALT + F1",                     hl.dsp.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland' && hyprctl dispatch submap global")                                                    ) -- # [hidden]
hl.define_submap("global", function() end)

--#!
--# Testing
hl.bind("SUPER + ALT + F11",                    hl.dsp.exec_cmd("bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | grep -v -i 'nipple' | grep -v -i 'pussy' | shuf -n 1); ACTION=$(notify-send 'Test notification with body image' 'This notification should contain your user account <b>image</b> and <a href=\'https://discord.com/app\'>Discord</a> <b>icon</b>. Oh and here is a random image in your Pictures folder: <img src=\'$RANDOM_IMAGE\' alt=\'Testing image\'/>' -a 'Hyprland keybind' -p -h 'string:image-path:/var/lib/AccountsService/icons/$USER' -t 6000 -i 'discord' -A 'openImage=Profile image' -A 'action2=Open the random image' -A 'action3=Useless button'); [[ $ACTION == *openImage ]] && xdg-open '/var/lib/AccountsService/icons/$USER'; [[ $ACTION == *action2 ]] && xdg-open \'$RANDOM_IMAGE\'''")
                                                                                                                                                                                                                                        ) -- # [hidden]
hl.bind("SUPER + ALT + F12",                    hl.dsp.exec_cmd("bash -c 'RANDOM_IMAGE=$(find ~/Pictures -type f | grep -v -i 'nipple' | grep -v -i 'pussy' | shuf -n 1); ACTION=$(notify-send 'Test notification' 'This notification should contain a random image in your <b>Pictures</b> folder and <a href=\'https://discord.com/app\'>Discord</a> <b>icon</b>.\n<i>Flick right to dismiss!</i>' -a 'Discord (fake)' -p -h 'string:image-path:$RANDOM_IMAGE' -t 6000 -i 'discord' -A 'openImage=Profile image' -A 'action2=Useless button'); [[ $ACTION == *openImage ]] && xdg-open '/var/lib/AccountsService/icons/$USER''")
                                                                                                                                                                                                                                        ) -- # [hidden]
hl.bind("SUPER + ALT + Equal",                  hl.dsp.exec_cmd("notify-send 'Urgent notification' 'Ah hell no' -u critical -a 'Hyprland keybind'")                                                                                     ) -- # [hidden]

--##! Session
hl.bind("SUPER + L",                            hl.dsp.exec_cmd("loginctl lock-session"),                                                                               {description = "Lock"}                                          ) -- Lock
hl.bind("SUPER + SHIFT + L",                    hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"),                                                               {locked = true, description = "Suspend system"}                 ) -- Sleep
--hl.bind("switch:on:Lid Switch",                 hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"),                                                               {locked = true}                                                 ) -- # [hidden] Suspend when laptop lid is closed, uncomment if for whatever reason it's not the default behavior

hl.bind("CTRL + SHIFT + ALT + SUPER + Delete",  hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"),                                                             {description = "Shutdown"}                                      ) -- # [hidden] Power off

--##! Screen
--# Zoom
hl.bind("SUPER + Minus",                        hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/zoom.sh decrease 0.3"),                                                {repeating = true}                                              ) -- Zoom out
hl.bind("SUPER + Equal",                        hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/zoom.sh increase 0.3"),                                                {repeating = true}                                              ) -- Zoom in
--# Zoom with keypad
hl.bind("SUPER + code:82",                      hl.dsp.exec_cmd("qs -c $qsConfig ipc call zoom zoomOut"),                                                               {repeating = true}                                              ) -- # [hidden] Zoom out
hl.bind("SUPER + code:86",                      hl.dsp.exec_cmd("qs -c $qsConfig ipc call zoom zoomIn"),                                                                {repeating = true}                                              ) -- # [hidden] Zoom in
hl.bind("SUPER + code:82",                      hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh decrease 0.1"),         {repeating = true}                                              ) -- # [hidden] Zoom out
hl.bind("SUPER + code:86",                      hl.dsp.exec_cmd("qs -c $qsConfig ipc call TEST_ALIVE || ~/.config/hypr/hyprland/scripts/zoom.sh increase 0.1"),         {repeating = true}                                              ) -- # [hidden] Zoom in

--##! Media
hl.bind("SUPER + SHIFT + N",                    hl.dsp.exec_cmd("playerctl next || playerctl position `bc <<< '100 * $(playerctl metadata mpris:length) / 1000000 / 100'`"), {locked = true}                                            ) -- Next track
hl.bind("XF86AudioNext",                        hl.dsp.exec_cmd("playerctl next || playerctl position `bc <<< '100 * $(playerctl metadata mpris:length) / 1000000 / 100'`"), {locked = true}                                            ) -- # [hidden]
hl.bind("XF86AudioPrev",                        hl.dsp.exec_cmd("playerctl previous"),                                                                                  {locked = true}                                                 ) -- # [hidden]
hl.bind("SUPER + SHIFT + ALT + mouse:275",      hl.dsp.exec_cmd("playerctl previous")                                                                                                                                                   ) -- # [hidden]
hl.bind("SUPER + SHIFT + ALT + mouse:276",      hl.dsp.exec_cmd("playerctl next || playerctl position `bc <<< '100 * $(playerctl metadata mpris:length) / 1000000 / 100'`")                                                             ) -- # [hidden]
hl.bind("SUPER + SHIFT + B",                    hl.dsp.exec_cmd("playerctl previous"),                                                                                  {locked = true}                                                 ) -- Previous track
hl.bind("SUPER + SHIFT + P",                    hl.dsp.exec_cmd("playerctl play-pause"),                                                                                {locked = true}                                                 ) -- Play/pause media
hl.bind("XF86AudioPlay",                        hl.dsp.exec_cmd("playerctl play-pause"),                                                                                {locked = true}                                                 ) -- # [hidden]
hl.bind("XF86AudioPause",                       hl.dsp.exec_cmd("playerctl play-pause"),                                                                                {locked = true}                                                 ) -- # [hidden]

--##! Apps
hl.bind("SUPER + Return",                      hl.dsp.exec_cmd("$terminal")                                                                                                                                                               ) -- Terminal
hl.bind("SUPER + T",                           hl.dsp.exec_cmd("$terminal")                                                                                                                                                               ) -- # [hidden] (terminal) (alt)
hl.bind("CTRL + ALT + T",                      hl.dsp.exec_cmd("$terminal")                                                                                                                                                               ) -- # [hidden] (terminal) (for Ubuntu people)
hl.bind("SUPER + E",                           hl.dsp.exec_cmd("$fileManager")                                                                                                                                                            ) -- File manager
hl.bind("SUPER + W",                           hl.dsp.exec_cmd("$browser")                                                                                                                                                                ) -- Browser
hl.bind("SUPER + C",                           hl.dsp.exec_cmd("$codeEditor")                                                                                                                                                             ) -- Code editor
hl.bind("CTRL + SUPER + SHIFT + ALT + W",      hl.dsp.exec_cmd("$officeSoftware")                                                                                                                                                         ) -- Office software
hl.bind("SUPER + X",                           hl.dsp.exec_cmd("$textEditor")                                                                                                                                                             ) -- Text editor
hl.bind("CTRL + SUPER + V",                    hl.dsp.exec_cmd("$volumeMixer")                                                                                                                                                            ) -- Volume mixer
hl.bind("SUPER + I",                           hl.dsp.exec_cmd("$settingsApp")                                                                                                                                                            ) -- Settings app
hl.bind("CTRL + SHIFT + Escape",               hl.dsp.exec_cmd("$taskManager")                                                                                                                                                            ) -- Task manager

--# Cursed stuff
--## Make window not amogus large
hl.bind("CTRL + SUPER + Backslash",            hl.dsp.window.resize({x = 640, y = 480, exact})                                                                                                                                                        ) -- # [hidden]
