import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true
    ContentSection {
        icon: "rule"
        title: Translation.tr("Policies")

        ConfigRow {
            ColumnLayout {
                // Weeb policy
                ContentSubsectionLabel {
                    text: Translation.tr("Weeb")
                }
                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Closet"),
                            value: 2
                        }
                    ]
                }
            }

            ColumnLayout {
                // AI policy
                ContentSubsectionLabel {
                    text: Translation.tr("AI")
                }
                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Local only"),
                            value: 2
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "wallpaper"
        title: Translation.tr("Background")

        ConfigSwitch {
            text: Translation.tr("Show clock")
            checked: Config.options.background.showClock
            onCheckedChanged: {
                Config.options.background.showClock = checked;
            }
        }

        ContentSubsection {
            title: Translation.tr("Wallpaper parallax")

            ConfigSwitch {
                text: Translation.tr("Vertical")
                checked: Config.options.background.parallax.vertical
                onCheckedChanged: {
                    Config.options.background.parallax.vertical = checked;
                }
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr("Depends on workspace")
                    checked: Config.options.background.parallax.enableWorkspace
                    onCheckedChanged: {
                        Config.options.background.parallax.enableWorkspace = checked;
                    }
                }
                ConfigSwitch {
                    text: Translation.tr("Depends on sidebars")
                    checked: Config.options.background.parallax.enableSidebar
                    onCheckedChanged: {
                        Config.options.background.parallax.enableSidebar = checked;
                    }
                }
            }
            ConfigSpinBox {
                text: Translation.tr("Preferred wallpaper zoom (%)")
                value: Config.options.background.parallax.workspaceZoom * 100
                from: 100
                to: 150
                stepSize: 1
                onValueChanged: {
                    console.log(value/100)
                    Config.options.background.parallax.workspaceZoom = value / 100;
                }
            }
        }
    }

    ContentSection {
        icon: "battery_android_full"
        title: Translation.tr("Battery")

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                text: Translation.tr("Low warning")
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.low = value;
                }
            }
            ConfigSpinBox {
                text: Translation.tr("Critical warning")
                value: Config.options.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.critical = value;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Automatic suspend")
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    content: Translation.tr("Automatically suspends the system when battery is low")
                }
            }
            ConfigSpinBox {
                text: Translation.tr("Suspend at")
                value: Config.options.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.suspend = value;
                }
            }
        }
    }

    ContentSection {
        icon: "call_to_action"
        title: Translation.tr("Dock")

        ConfigSwitch {
            text: Translation.tr("Enable")
            checked: Config.options.dock.enable
            onCheckedChanged: {
                Config.options.dock.enable = checked;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: Translation.tr("Hover to reveal")
                checked: Config.options.dock.hoverToReveal
                onCheckedChanged: {
                    Config.options.dock.hoverToReveal = checked;
                }
            }
            ConfigSwitch {
                text: Translation.tr("Pinned on startup")
                checked: Config.options.dock.pinnedOnStartup
                onCheckedChanged: {
                    Config.options.dock.pinnedOnStartup = checked;
                }
            }
        }
        ConfigSwitch {
            text: Translation.tr("Tint app icons")
            checked: Config.options.dock.monochromeIcons
            onCheckedChanged: {
                Config.options.dock.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        icon: "side_navigation"
        title: Translation.tr("Sidebars")

        ConfigSwitch {
            text: Translation.tr('Keep right sidebar loaded')
            checked: Config.options.sidebar.keepRightSidebarLoaded
            onCheckedChanged: {
                Config.options.sidebar.keepRightSidebarLoaded = checked;
            }
            StyledToolTip {
                content: Translation.tr("When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a custom kernel like linux-cachyos might help")
            }
        }

        ContentSubsection {
            title: Translation.tr("Corner open")
            tooltip: Translation.tr("Allows you to open sidebars by clicking or hovering screen corners regardless of bar position")
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr("Enable")
                    checked: Config.options.sidebar.cornerOpen.enable
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.enable = checked;
                    }
                }
                ConfigSwitch {
                    text: Translation.tr("Hover to trigger")
                    checked: Config.options.sidebar.cornerOpen.clickless
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.clickless = checked;
                    }

                    StyledToolTip {
                        content: Translation.tr("When this is off you'll have to click")
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr("Place at bottom")
                    checked: Config.options.sidebar.cornerOpen.bottom
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.bottom = checked;
                    }

                    StyledToolTip {
                        content: Translation.tr("Place the corners to trigger at the bottom")
                    }
                }
                ConfigSwitch {
                    text: Translation.tr("Value scroll")
                    checked: Config.options.sidebar.cornerOpen.valueScroll
                    onCheckedChanged: {
                        Config.options.sidebar.cornerOpen.valueScroll = checked;
                    }

                    StyledToolTip {
                        content: Translation.tr("Brightness and volume")
                    }
                }
            }
            ConfigSwitch {
                text: Translation.tr("Visualize region")
                checked: Config.options.sidebar.cornerOpen.visualize
                onCheckedChanged: {
                    Config.options.sidebar.cornerOpen.visualize = checked;
                }

                StyledToolTip {
                    content: "When this is off you'll have to click"
                }
            }
            ConfigRow {
                ConfigSpinBox {
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
            text: Translation.tr("Enable")
            checked: Config.options.overview.enable
            onCheckedChanged: {
                Config.options.overview.enable = checked;
            }
        }
        ConfigSpinBox {
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
            text: Translation.tr('Show regions of potential interest')
            checked: Config.options.screenshotTool.showContentRegions
            onCheckedChanged: {
                Config.options.screenshotTool.showContentRegions = checked;
            }
            StyledToolTip {
                content: Translation.tr("Such regions could be images or parts of the screen that have some containment.\nMight not always be accurate.\nThis is done with an image processing algorithm run locally and no AI is used.")
            }
        }
    }

    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface Language")
            tooltip: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            ConfigSelectionArray {
                id: languageSelector
                currentValue: Config.options.language.ui
                onSelected: newValue => {
                    Config.options.language.ui = newValue;
                    reloadNotice.visible = true;
                }
                options: {
                    var baseOptions = [
                        {
                            displayName: Translation.tr("Auto (System)"),
                            value: "auto"
                        }
                    ];

                    // Generate language options from available languages
                    // Intl.DisplayNames is not used. Show the language code with underscore replaced by hyphen.
                    for (var i = 0; i < Translation.availableLanguages.length; i++) {
                        var lang = Translation.availableLanguages[i];
                        var displayName = lang.replace('_', '-');
                        baseOptions.push({
                            displayName: displayName,
                            value: lang
                        });
                    }

                    return baseOptions;
                }
            }

            NoticeBox {
                id: reloadNotice
                visible: false
                Layout.topMargin: 8
                Layout.fillWidth: true

                text: Translation.tr("Language setting saved. Please restart Quickshell (Ctrl+Super+R) to apply the new language.")
            }
        }
    }
}
