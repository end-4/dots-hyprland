-- ######## Window rules ########

-- Disable blur for xwayland context menus
hl.window_rule({match = {class = "^()$" }, match = {title = "^()$" }, no_blur = true })

-- Disable blur for every window
hl.window_rule({match = {class = ".*" }, no_blur = true })

-- Floating
hl.window_rule({match = {title = "^(Open File)(.*)$" },                                                         center = true})
hl.window_rule({match = {title = "^(Open File)(.*)$" },                                                         float = true})
hl.window_rule({match = {title = "^(Select a File)(.*)$" },                                                     center = true})
hl.window_rule({match = {title = "^(Select a File)(.*)$" },                                                     float = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },                                                  center = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },                                                  float = true})
hl.window_rule({match = {title = "^(Choose wallpaper)(.*)$" },                                                  size = {"(monitor_w*0.60)", "(monitor_h*0.65)"} })
hl.window_rule({match = {title = "^(Open Folder)(.*)$" },                                                       center = true})
hl.window_rule({match = {title = "^(Open Folder)(.*)$" },                                                       float = true})
hl.window_rule({match = {title = "^(Save As)(.*)$" },                                                           center = true})
hl.window_rule({match = {title = "^(Save As)(.*)$" },                                                           float = true})
hl.window_rule({match = {title = "^(Library)(.*)$" },                                                           center = true})
hl.window_rule({match = {title = "^(Library)(.*)$" },                                                           float = true})
hl.window_rule({match = {title = "^(File Upload)(.*)$" },                                                       center = true})
hl.window_rule({match = {title = "^(File Upload)(.*)$" },                                                       float = true})
hl.window_rule({match = {title = "^(.*)(wants to save)$" },                                                     center = true})
hl.window_rule({match = {title = "^(.*)(wants to save)$" },                                                     float = true})
hl.window_rule({match = {title = "^(.*)(wants to open)$" },                                                     center = true})
hl.window_rule({match = {title = "^(.*)(wants to open)$" },                                                     float = true})
hl.window_rule({match = {class = "^(blueberry\\.py)$" },                                                        float = true})
hl.window_rule({match = {class = "^(guifetch)$" },                                                              float = true}) -- FlafyDev/guifetch
hl.window_rule({match = {class = "^(pavucontrol)$" },                                                           float = true})
hl.window_rule({match = {class = "^(pavucontrol)$" },                                                           size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(pavucontrol)$" },                                                           center = true})
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },                                            float = true})
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },                                            size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(org.pulseaudio.pavucontrol)$" },                                            center = true})
hl.window_rule({match = {class = "^(nm-connection-editor)$" },                                                  float = true})
hl.window_rule({match = {class = "^(nm-connection-editor)$" },                                                  size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })
hl.window_rule({match = {class = "^(nm-connection-editor)$" },                                                  center = true})
hl.window_rule({match = {class = ".*plasmawindowed.*" },                                                        float = true})
hl.window_rule({match = {class = "cm_.*" },                                                                     float = true})
hl.window_rule({match = {class = ".*bluedevilwizard" },                                                         float = true})
hl.window_rule({match = {title = ".*Welcome" },                                                                 float = true})
hl.window_rule({match = {title = "^(illogical-impulse Settings)$" },                                            float = true})
hl.window_rule({match = {title = ".*Shell conflicts.*" },                                                       float = true})
hl.window_rule({match = {class = "rg.freedesktop.impl.portal.desktop.kde" },                                    float = true})
hl.window_rule({match = {class = "rg.freedesktop.impl.portal.desktop.kde" },                                    size = {"(monitor_w*0.60)", "(monitor_h*0.65)"} })
hl.window_rule({match = {class = "^(Zotero)$" },                                                                float = true})
hl.window_rule({match = {class = "^(Zotero)$" },                                                                size = {"(monitor_w*0.45)", "(monitor_h*0.45)"} })

-- Move
-- kde-material-you-colors spawns a window when changing dark/light theme. This is to make sure it doesn't interfere at all.
hl.window_rule({match = {class = "^(plasma-changeicons)$" },                                                    float = true})
hl.window_rule({match = {class = "^(plasma-changeicons)$" },                                                    no_initial_focus = true})
hl.window_rule({match = {class = "^(plasma-changeicons)$" },                                                    move = {999999, 999999}})
-- stupid dolphin copy
hl.window_rule({match = {title = "^(Copying — Dolphin)$" },                                                     move = {40, 80}})

-- Tiling
hl.window_rule({match = {class = "^dev\\.warp\\.Warp$" },                                                       tile = true})

-- Picture-in-Picture
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },                           float = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },                           keep_aspect_ratio = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },                           move = {"(monitor_w*0.73)", "(monitor_h*0.72)"} })
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },                           size = {"(monitor_w*0.25)", "(monitor_h*0.25)"} })
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },                           float = true})
hl.window_rule({match = {title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },                           pin = true})

-- Screen sharing
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" },                                     float = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" },                                     pin = true})
hl.window_rule({match = {title = ".*is sharing (a window|your screen).*" },                                     move = {"(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)"} })

-- --- Tearing ---
hl.window_rule({match = {title = ".*\\.exe" },                                                                  immediate = true})
hl.window_rule({match = {title = ".*minecraft.*" },                                                             immediate = true})
hl.window_rule({match = {class = "^(steam_app).*" },                                                            immediate = true})

-- Fix Jetbrain IDEs focus/rerendering problem
hl.window_rule({match = {class = "^jetbrains-.*$" }, match = {float = 1 }, match = {title = "^$|^\\s$|^win\\d+$" }, no_initial_focus = true})

-- No shadow for tiled windows (matches windows that are not floating).
hl.window_rule({match = {float = 0 },                                                                           no_shadow = true})

-- ######## Workspace rules ########
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

-- ######## Layer rules ########
hl.layer_rule({ match = { namespace = ".*" },                                                                   xray = true})
--hl.layer_rule({ match = { namespace = ".*" },                                                                   no_anim = true})
hl.layer_rule({ match = { namespace = walker },                                                                 no_anim = true})
hl.layer_rule({ match = { namespace = selection },                                                              no_anim = true})
hl.layer_rule({ match = { namespace = overview },                                                               no_anim = true})
hl.layer_rule({ match = { namespace = anyrun },                                                                 no_anim = true})
hl.layer_rule({ match = { namespace = "indicator.*" },                                                          no_anim = true})
hl.layer_rule({ match = { namespace = osk },                                                                    no_anim = true})
hl.layer_rule({ match = { namespace = hyprpicker },                                                             no_anim = true})

hl.layer_rule({ match = { namespace = noanim },                                                                 no_anim = true})
hl.layer_rule({ match = { namespace = "gtk-layer-shell" },                                                      blur = true})
hl.layer_rule({ match = { namespace = "gtk-layer-shell" },                                                      ignore_alpha = 0})
hl.layer_rule({ match = { namespace = launcher },                                                               blur = true})
hl.layer_rule({ match = { namespace = launcher },                                                               ignore_alpha = 0.5})
hl.layer_rule({ match = { namespace = notifications },                                                          blur = true})
hl.layer_rule({ match = { namespace = notifications },                                                          ignore_alpha = 0.69})
--hl.layer_rule({ match = { namespace = logout_dialog }, -- wlogout                                               blur = true})

-- ags
hl.layer_rule({ match = { namespace = "sideleft.*" },                                                           animation = "slide left"})
hl.layer_rule({ match = { namespace = "sideright.*" },                                                          animation = "slide right"})
hl.layer_rule({ match = { namespace = "session[0-9]*" },                                                        blur = true})
hl.layer_rule({ match = { namespace = "bar[0-9]*" },                                                            blur = true})
hl.layer_rule({ match = { namespace = "bar[0-9]*" },                                                            ignore_alpha = 0.6})
hl.layer_rule({ match = { namespace = "barcorner.*" },                                                          blur = true})
hl.layer_rule({ match = { namespace = "barcorner.*" },                                                          ignore_alpha = 0.6})
hl.layer_rule({ match = { namespace = "dock[0-9]*" },                                                           blur = true})
hl.layer_rule({ match = { namespace = "dock[0-9]*" },                                                           ignore_alpha = 0.6})
hl.layer_rule({ match = { namespace = "indicator.*" },                                                          blur = true})
hl.layer_rule({ match = { namespace = "indicator.*" },                                                          ignore_alpha = 0.6})
hl.layer_rule({ match = { namespace = "overview[0-9]*" },                                                       blur = true})
hl.layer_rule({ match = { namespace = "overview[0-9]*" },                                                       ignore_alpha = 0.6})
hl.layer_rule({ match = { namespace = "cheatsheet[0-9]*" },                                                     blur = true})
hl.layer_rule({ match = { namespace = "cheatsheet[0-9]*" },                                                     ignore_alpha = 0.6})
hl.layer_rule({ match = { namespace = "sideright[0-9]*" },                                                      blur = true})
hl.layer_rule({ match = { namespace = "sideright[0-9]*" },                                                      ignore_alpha = 0.6})
hl.layer_rule({ match = { namespace = "sideleft[0-9]*" },                                                       blur = true})
hl.layer_rule({ match = { namespace = "sideleft[0-9]*" },                                                       ignore_alpha = 0.6})
hl.layer_rule({ match = { namespace = "indicator.*" },                                                          blur = true})
hl.layer_rule({ match = { namespace = "indicator.*" },                                                          ignore_alpha = 0.6})
hl.layer_rule({ match = { namespace = "osk[0-9]*" },                                                            blur = true})
hl.layer_rule({ match = { namespace = "osk[0-9]*" },                                                            ignore_alpha = 0.6})

-- Quickshell
-- Quickshell: illogical-impulse
hl.layer_rule({ match = { namespace = "quickshell:.*" },                                                        blur_popups = true})
hl.layer_rule({ match = { namespace = "quickshell:.*" },                                                        blur = true})
hl.layer_rule({ match = { namespace = "quickshell:.*" },                                                        ignore_alpha = 0.79})
hl.layer_rule({ match = { namespace = "quickshell:bar" },                                                       animation = "slide"})
hl.layer_rule({ match = { namespace = "quickshell:actionCenter" },                                              no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:cheatsheet" },                                                animation = "slide bottom"})
hl.layer_rule({ match = { namespace = "quickshell:dock" },                                                      animation = "slide bottom"})
hl.layer_rule({ match = { namespace = "quickshell:screenCorners" },                                             animation = "popin 120%"})
hl.layer_rule({ match = { namespace = "quickshell:lockWindowPusher" },                                          no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" },                                         animation = "fade"})
hl.layer_rule({ match = { namespace = "quickshell:overlay" },                                                   no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:overlay" },                                                   ignore_alpha = 1})
hl.layer_rule({ match = { namespace = "quickshell:overview" },                                                  no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:osk" },                                                       animation = "slide bottom"})
hl.layer_rule({ match = { namespace = "quickshell:polkit" },                                                    no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:popup" },                                                     xray = false}) -- No weird color for bar tooltips (this in theory should suffice)
hl.layer_rule({ match = { namespace = "quickshell:popup" },                                                     ignore_alpha = 1}) -- No weird color for bar tooltips (but somehow this is necessary)
hl.layer_rule({ match = { namespace = "quickshell:mediaControls" },                                             ignore_alpha = 1}) -- Same as above
hl.layer_rule({ match = { namespace = "quickshell:reloadPopup" },                                               animation = "slide"})
hl.layer_rule({ match = { namespace = "quickshell:regionSelector" },                                            no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:screenshot" },                                                no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:session" },                                                   blur = true})
hl.layer_rule({ match = { namespace = "quickshell:session" },                                                   no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:session" },                                                   ignore_alpha = 0})
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" },                                              animation = "slide right"})
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" },                                               animation = "slide left"})
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" },                                               animation = "slide"})
hl.layer_rule({ match = { namespace = "quickshell:osk" },                                                       order = -1})
-- Quickshell: waffles
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" },                                         animation = "slide top"})
hl.layer_rule({ match = { namespace = "quickshell:wNotificationCenter" },                                       no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:wOnScreenDisplay" },                                          no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:wStartMenu" },                                                no_anim = true})
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" },                                                 ignore_alpha = 0})
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" },                                                 no_anim = true})

-- Launchers need to be FAST
hl.layer_rule({ match = { namespace = "gtk4-layer-shell" },                                                     no_anim = true})
