import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "wallpaper"
        title: Translation.tr("Background")

        ConfigSwitch {
            buttonIcon: "nest_clock_farsight_analog"
            text: Translation.tr("Show clock")
            checked: Config.options.background.clock.show
            onCheckedChanged: {
                Config.options.background.clock.show = checked;
            }
        }
            

        ConfigSpinBox {
            icon: "loupe"
            text: Translation.tr("Scale (%)")
            value: Config.options.background.clock.scale * 100
            from: 1
            to: 200
            stepSize: 2
            onValueChanged: {
                Config.options.background.clock.scale = value / 100;
            }
        }

        ContentSubsection {
            title: Translation.tr("Clock style")
            ConfigSelectionArray {
                currentValue: Config.options.background.clock.style
                onSelected: newValue => {
                    Config.options.background.clock.style = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Simple digital"),
                        icon: "timer_10",
                        value: "digital"
                    },
                    {
                        displayName: Translation.tr("Material cookie"),
                        icon: "cookie",
                        value: "cookie"
                    }
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Cookie clock settings")
            ConfigSpinBox {
                visible: Config.options.background.clock.style === "cookie"
                icon: "add_triangle"
                text: Translation.tr("Sides")
                value: Config.options.background.clock.cookie.sides
                from: 1
                to: 36
                stepSize: 1
                onValueChanged: {
                    Config.options.background.clock.cookie.sides = value;
                }
            }

            ConfigSwitch {
                visible: Config.options.background.clock.style === "cookie"
                buttonIcon: "autoplay"
                text: Translation.tr("Constantly rotate")
                checked: Config.options.background.clock.cookie.constantlyRotate
                onCheckedChanged: {
                    Config.options.background.clock.cookie.constantlyRotate = checked;
                }
                StyledToolTip {
                    text: "Makes the clock always rotate. This is extremely expensive\n(expect 50% usage on Intel UHD Graphics) and thus impractical."
                }
            }

            ConfigRow {
                visible: Config.options.background.clock.style === "cookie"

                ConfigSwitch {
                    enabled: Config.options.background.clock.style === "cookie" && Config.options.background.clock.cookie.dialNumberStyle === "dots" || Config.options.background.clock.cookie.dialNumberStyle === "full"
                    buttonIcon: "brightness_7"
                    text: Translation.tr("Hour marks")
                    checked: Config.options.background.clock.cookie.hourMarks
                    onEnabledChanged: {
                        checked = Config.options.background.clock.cookie.hourMarks;
                    }
                    onCheckedChanged: {
                        Config.options.background.clock.cookie.hourMarks = checked;
                    }
                    StyledToolTip {
                        text: "Can only be turned on using the 'Dots' or 'Full' dial style for aesthetic reasons"
                    }
                }

                ConfigSwitch {
                    enabled: Config.options.background.clock.style === "cookie" && Config.options.background.clock.cookie.dialNumberStyle !== "numbers"
                    buttonIcon: "timer_10"
                    text: Translation.tr("Digits in the middle")
                    checked: Config.options.background.clock.cookie.timeIndicators
                    onEnabledChanged: {
                        checked = Config.options.background.clock.cookie.timeIndicators;
                    }
                    onCheckedChanged: {
                        Config.options.background.clock.cookie.timeIndicators = checked;
                    }
                    StyledToolTip {
                        text: "Can't be turned on when using 'Numbers' dial style for aesthetic reasons"
                    }
                }
            }
        }
        
        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Dial style")
            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.dialNumberStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.dialNumberStyle = newValue;
                    if (newValue !== "dots" && newValue !== "full") {
                        Config.options.background.clock.cookie.hourMarks = false;
                    }
                    if (newValue === "numbers") {
                        Config.options.background.clock.cookie.timeIndicators = false;
                    }
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "none"
                    },
                    {
                        displayName: Translation.tr("Dots"),
                        icon: "graph_6",
                        value: "dots"
                    },
                    {
                        displayName: Translation.tr("Full"),
                        icon: "history_toggle_off",
                        value: "full"
                    },
                    {
                        displayName: Translation.tr("Numbers"),
                        icon: "counter_1",
                        value: "numbers"
                    }
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Hour hand")
            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.hourHandStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.hourHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Hollow"),
                        icon: "circle",
                        value: "hollow"
                    },
                    {
                        displayName: Translation.tr("Fill"),
                        icon: "eraser_size_5",
                        value: "fill"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Minute hand")

            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.minuteHandStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.minuteHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Thin"),
                        icon: "line_end",
                        value: "thin"
                    },
                    {
                        displayName: Translation.tr("Medium"),
                        icon: "eraser_size_2",
                        value: "medium"
                    },
                    {
                        displayName: Translation.tr("Bold"),
                        icon: "eraser_size_4",
                        value: "bold"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Second hand")

            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.secondHandStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.secondHandStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Line"),
                        icon: "line_end",
                        value: "line"
                    },
                    {
                        displayName: Translation.tr("Dot"),
                        icon: "adjust",
                        value: "dot"
                    },
                ]
            }
        }

        ContentSubsection {
            visible: Config.options.background.clock.style === "cookie"
            title: Translation.tr("Date style")

            ConfigSelectionArray {
                currentValue: Config.options.background.clock.cookie.dateStyle
                onSelected: newValue => {
                    Config.options.background.clock.cookie.dateStyle = newValue;
                }
                options: [
                    {
                        displayName: "",
                        icon: "block",
                        value: "hide"
                    },
                    {
                        displayName: Translation.tr("Bubble"),
                        icon: "bubble_chart",
                        value: "bubble"
                    },
                    {
                        displayName: Translation.tr("Border"),
                        icon: "rotate_right",
                        value: "border"
                    },
                    {
                        displayName: Translation.tr("Rect"),
                        icon: "rectangle",
                        value: "rect"
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Quote settings")
            ConfigSwitch {
                buttonIcon: "format_quote"
                text: Translation.tr("Show quote")
                checked: Config.options.background.showQuote
                onCheckedChanged: {
                    Config.options.background.showQuote = checked;
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Quote")
                text: Config.options.background.quote
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.background.quote = text;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Wallpaper parallax")

            ConfigSwitch {
                buttonIcon: "unfold_more_double"
                text: Translation.tr("Vertical")
                checked: Config.options.background.parallax.vertical
                onCheckedChanged: {
                    Config.options.background.parallax.vertical = checked;
                }
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "counter_1"
                    text: Translation.tr("Depends on workspace")
                    checked: Config.options.background.parallax.enableWorkspace
                    onCheckedChanged: {
                        Config.options.background.parallax.enableWorkspace = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "side_navigation"
                    text: Translation.tr("Depends on sidebars")
                    checked: Config.options.background.parallax.enableSidebar
                    onCheckedChanged: {
                        Config.options.background.parallax.enableSidebar = checked;
                    }
                }
            }
            ConfigSpinBox {
                icon: "loupe"
                text: Translation.tr("Preferred wallpaper zoom (%)")
                value: Config.options.background.parallax.workspaceZoom * 100
                from: 100
                to: 150
                stepSize: 1
                onValueChanged: {
                    Config.options.background.parallax.workspaceZoom = value / 100;
                }
            }
        }
    }

    ContentSection {
        icon: "bottom_panel_close"
        title: Translation.tr("Quick Panel")
        
        ContentSubsection {
            title: Translation.tr("Quick panel style")

            ConfigSelectionArray {
                currentValue: Config.options.quickToggles.type
                onSelected: newValue => {
                    Config.options.quickToggles.type = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "radio",
                        value: "classic"
                    },
                    {
                        displayName: Translation.tr("Material"),
                        icon: "texture",
                        value: "material"
                    }
                ]
            }
        }

        ConfigRow{
            visible: Config.options.quickToggles.type === "material"
            ContentSubsection {
                title: Translation.tr("Mode")
                ConfigSelectionArray {
                    currentValue: Config.options.quickToggles.material.mode
                    onSelected: newValue => {
                        Config.options.quickToggles.material.mode = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Compact"),
                            icon: "tile_small",
                            value: "compact"
                        },
                        {
                            displayName: Translation.tr("Medium"),
                            icon: "tile_medium",
                            value: "medium"
                        },
                        {
                            displayName: Translation.tr("Large"),
                            icon: "tile_large",
                            value: "large"
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Leftover alignment")
                tooltip: Translation.tr("Left alignment may have some problems")
                ConfigSelectionArray {
                    currentValue: Config.options.quickToggles.material.align
                    onSelected: newValue => {
                        Config.options.quickToggles.material.align = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Left"),
                            icon: "align_horizontal_left",
                            value: "left"
                        },
                        {
                            displayName: Translation.tr("Center"),
                            icon: "align_horizontal_center",
                            value: "center"
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "align_horizontal_right",
                            value: "right"
                        }
                    ]
                }
            }
        }

        ContentSubsection {
            visible: Config.options.quickToggles.type === "material"
            title: Translation.tr("Layout (left-to-right)")
            tooltip: Translation.tr("Press and hold: Toggle size\nMiddleClick: Toggle\nLeft/Right Click: Move")
            ConfigDragArray {
                initial: Config.options.quickToggles.material.toggles
                onSelected: newValue => {
                    Config.options.quickToggles.material.toggles = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Network"),
                        icon: "network_cell",
                        value: "network"
                    },
                    {
                        displayName: Translation.tr("Idle"),
                        icon: "coffee",
                        value: "idleinhibitor"
                    },
                    {
                        displayName: Translation.tr("Bluetooth"),
                        icon: "bluetooth",
                        value: "bluetooth"
                    },
                    {
                        displayName: Translation.tr("Game Mode"),
                        icon: "gamepad",
                        value: "gamemode"
                    },
                    {
                        displayName: Translation.tr("Dark Mode"),
                        icon: "contrast",
                        value: "darkmode"
                    },
                    {
                        displayName: Translation.tr("EasyEffects"),
                        icon: "instant_mix",
                        value: "easyeffects"
                    },
                    {
                        displayName: Translation.tr("Keyboard"),
                        icon: "keyboard_alt",
                        value: "showkeyboard"
                    },
                    {
                        displayName: Translation.tr("Toggle Mic"),
                        icon: "mic",
                        value: "togglemic"
                    },
                    {
                        displayName: Translation.tr("WARP"),
                        icon: "shield",
                        value: "cloudflarewarp"
                    },
                    {
                        displayName: Translation.tr("Night Light"),
                        icon: "mode_night",
                        value: "nightlight"
                    },
                    {
                        displayName: Translation.tr("Screenshot"),
                        icon: "screenshot_region",
                        value: "screensnip"
                    },
                    {
                        displayName: Translation.tr("Color Picker"),
                        icon: "colorize",
                        value: "colorpicker"
                    },
                    {
                        displayName: Translation.tr("Profile"),
                        icon: "energy_savings_leaf",
                        value: "performanceprofile"
                    },
                    {
                        displayName: Translation.tr("Silent"),
                        icon: "notifications_active",
                        value: "silent"
                    }
                ]
            }
        }

        ConfigRow {
            visible: Config.options.quickToggles.type === "material"
            ConfigSwitch {
                buttonIcon: "volume_up"
                text: Translation.tr("Show Volume")
                checked: Config.options.quickToggles.material.showVolume
                onCheckedChanged: {
                    Config.options.quickToggles.material.showVolume = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "brightness_6"
                text: Translation.tr("Show Brightness")
                checked: Config.options.quickToggles.material.showBrightness
                onCheckedChanged: {
                    Config.options.quickToggles.material.showBrightness = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "panorama_wide_angle"
                text: Translation.tr("Border")
                checked: Config.options.quickToggles.material.border
                onCheckedChanged: {
                    Config.options.quickToggles.material.border = checked;
                }
            }
        }
        
    }

    ContentSection {
        icon: "point_scan"
        title: Translation.tr("Crosshair overlay")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Crosshair code (in Valorant's format)")
            text: Config.options.crosshair.code
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.crosshair.code = text;
            }
        }

        RowLayout {
            StyledText {
                Layout.leftMargin: 10
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallie
                text: Translation.tr("Press Super+G to toggle appearance")
            }
            Item {
                Layout.fillWidth: true
            }
            RippleButtonWithIcon {
                id: editorButton
                buttonRadius: Appearance.rounding.full
                materialIcon: "open_in_new"
                mainText: Translation.tr("Open editor")
                onClicked: {
                    Qt.openUrlExternally(`https://www.vcrdb.net/builder?c=${Config.options.crosshair.code}`);
                }
                StyledToolTip {
                    text: "www.vcrdb.net"
                }
            }
        }
    }

    ContentSection {
        icon: "call_to_action"
        title: Translation.tr("Dock")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.dock.enable
            onCheckedChanged: {
                Config.options.dock.enable = checked;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "highlight_mouse_cursor"
                text: Translation.tr("Hover to reveal")
                checked: Config.options.dock.hoverToReveal
                onCheckedChanged: {
                    Config.options.dock.hoverToReveal = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Pinned on startup")
                checked: Config.options.dock.pinnedOnStartup
                onCheckedChanged: {
                    Config.options.dock.pinnedOnStartup = checked;
                }
            }
        }
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr("Tint app icons")
            checked: Config.options.dock.monochromeIcons
            onCheckedChanged: {
                Config.options.dock.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        icon: "lock"
        title: Translation.tr("Lock screen")

        ConfigSwitch {
            buttonIcon: "account_circle"
            text: Translation.tr('Launch on startup')
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: {
                Config.options.lock.launchOnStartup = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Security")

            ConfigSwitch {
                buttonIcon: "settings_power"
                text: Translation.tr('Require password to power off/restart')
                checked: Config.options.lock.security.requirePasswordToPower
                onCheckedChanged: {
                    Config.options.lock.security.requirePasswordToPower = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Remember that on most devices one can always hold the power button to force shutdown\nThis only makes it a tiny bit harder for accidents to happen")
                }
            }

            ConfigSwitch {
                buttonIcon: "key_vertical"
                text: Translation.tr('Also unlock keyring')
                checked: Config.options.lock.security.unlockKeyring
                onCheckedChanged: {
                    Config.options.lock.security.unlockKeyring = checked;
                }
                StyledToolTip {
                    text: Translation.tr("This is usually safe and needed for your browser and AI sidebar anyway\nMostly useful for those who use lock on startup instead of a display manager that does it (GDM, SDDM, etc.)")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Style: general")

            ConfigSwitch {
                buttonIcon: "center_focus_weak"
                text: Translation.tr('Center clock')
                checked: Config.options.lock.centerClock
                onCheckedChanged: {
                    Config.options.lock.centerClock = checked;
                }
            }

            ConfigSwitch {
                buttonIcon: "info"
                text: Translation.tr('Show "Locked" text')
                checked: Config.options.lock.showLockedText
                onCheckedChanged: {
                    Config.options.lock.showLockedText = checked;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Style: Blurred")

            ConfigSwitch {
                buttonIcon: "blur_on"
                text: Translation.tr('Enable blur')
                checked: Config.options.lock.blur.enable
                onCheckedChanged: {
                    Config.options.lock.blur.enable = checked;
                }
            }

            ConfigSpinBox {
                icon: "loupe"
                text: Translation.tr("Extra wallpaper zoom (%)")
                value: Config.options.lock.blur.extraZoom * 100
                from: 1
                to: 150
                stepSize: 2
                onValueChanged: {
                    Config.options.lock.blur.extraZoom = value / 100;
                }
            }
        }
    }

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Timeout duration (if not defined by notification) (ms)")
            value: Config.options.notifications.timeout
            from: 1000
            to: 60000
            stepSize: 1000
            onValueChanged: {
                Config.options.notifications.timeout = value;
            }
        }
    }

    

    ContentSection {
        icon: "side_navigation"
        title: Translation.tr("Sidebars")

        ConfigSwitch {
            buttonIcon: "memory"
            text: Translation.tr('Keep right sidebar loaded')
            checked: Config.options.sidebar.keepRightSidebarLoaded
            onCheckedChanged: {
                Config.options.sidebar.keepRightSidebarLoaded = checked;
            }
            StyledToolTip {
                text: Translation.tr("When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help")
            }
        }

        ContentSubsection {
            title: Translation.tr("Corner open")
            tooltip: Translation.tr("Allows you to open sidebars by clicking or hovering screen corners regardless of bar position")
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "check"
                    text: Translation.tr("Enable")
                    checked: Config.options.sidebar.cornerOpen.enable
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.enable = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "highlight_mouse_cursor"
                    text: Translation.tr("Hover to trigger")
                    checked: Config.options.sidebar.cornerOpen.clickless
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.clickless = checked;
                    }

                    StyledToolTip {
                        text: Translation.tr("When this is off you'll have to click")
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "vertical_align_bottom"
                    text: Translation.tr("Place at bottom")
                    checked: Config.options.sidebar.cornerOpen.bottom
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.bottom = checked;
                    }

                    StyledToolTip {
                        text: Translation.tr("Place the corners to trigger at the bottom")
                    }
                }
                ConfigSwitch {
                    buttonIcon: "unfold_more_double"
                    text: Translation.tr("Value scroll")
                    checked: Config.options.sidebar.cornerOpen.valueScroll
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.valueScroll = checked;
                    }

                    StyledToolTip {
                        text: Translation.tr("Brightness and volume")
                    }
                }
            }
            ConfigSwitch {
                buttonIcon: "visibility"
                text: Translation.tr("Visualize region")
                checked: Config.options.sidebar.cornerOpen.visualize
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.visualize = checked;
                }
            }
            ConfigRow {
                ConfigSpinBox {
                    icon: "arrow_range"
                    text: Translation.tr("Region width")
                    value: Config.options.sidebar.cornerOpen.cornerRegionWidth
                    from: 1
                    to: 300
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.cornerOpen.cornerRegionWidth = value;
                    }
                }
                ConfigSpinBox {
                    icon: "height"
                    text: Translation.tr("Region height")
                    value: Config.options.sidebar.cornerOpen.cornerRegionHeight
                    from: 1
                    to: 300
                    stepSize: 1
                    onValueChanged: {
                        Config.options.sidebar.cornerOpen.cornerRegionHeight = value;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "voting_chip"
        title: Translation.tr("On-screen display")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Timeout (ms)")
            value: Config.options.osd.timeout
            from: 100
            to: 3000
            stepSize: 100
            onValueChanged: {
                Config.options.osd.timeout = value;
            }
        }
    }

    ContentSection {
        icon: "overview_key"
        title: Translation.tr("Overview")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.overview.enable
            onCheckedChanged: {
                Config.options.overview.enable = checked;
            }
        }
        ConfigSpinBox {
            icon: "loupe"
            text: Translation.tr("Scale (%)")
            value: Config.options.overview.scale * 100
            from: 1
            to: 100
            stepSize: 1
            onValueChanged: {
                Config.options.overview.scale = value / 100;
            }
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "splitscreen_bottom"
                text: Translation.tr("Rows")
                value: Config.options.overview.rows
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.rows = value;
                }
            }
            ConfigSpinBox {
                icon: "splitscreen_right"
                text: Translation.tr("Columns")
                value: Config.options.overview.columns
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.columns = value;
                }
            }
        }
    }

    ContentSection {
        icon: "screenshot_frame_2"
        title: Translation.tr("Screenshot tool")

        ConfigSwitch {
            buttonIcon: "nearby"
            text: Translation.tr('Show regions of potential interest')
            checked: Config.options.screenshotTool.showContentRegions
            onCheckedChanged: {
                Config.options.screenshotTool.showContentRegions = checked;
            }
            StyledToolTip {
                text: Translation.tr("Such regions could be images or parts of the screen that have some containment.\nMight not always be accurate.\nThis is done with an image processing algorithm run locally and no AI is used.")
            }
        }
    }
}
