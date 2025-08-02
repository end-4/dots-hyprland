import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true
    ContentSection {
        title: Translation.tr("Policies")

        ConfigRow {
            ColumnLayout {
                // Weeb policy
                ContentSubsectionLabel {
                    text: Translation.tr("Weeb")
                }
                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    configOptionName: "policies.weeb"
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
                    configOptionName: "policies.ai"
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
        title: Translation.tr("Bar")

        ConfigSelectionArray {
            currentValue: Config.options.bar.cornerStyle
            configOptionName: "bar.cornerStyle"
            onSelected: newValue => {
                Config.options.bar.cornerStyle = newValue;
            }
            options: [
                {
                    displayName: Translation.tr("Hug"),
                    value: 0
                },
                {
                    displayName: Translation.tr("Float"),
                    value: 1
                },
                {
                    displayName: Translation.tr("Plain rectangle"),
                    value: 2
                }
            ]
        }

        ContentSubsection {
            title: Translation.tr("Overall appearance")
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr('Borderless')
                    checked: Config.options.bar.borderless
                    onCheckedChanged: {
                        Config.options.bar.borderless = checked;
                    }
                }
                ConfigSwitch {
                    text: Translation.tr('Show background')
                    checked: Config.options.bar.showBackground
                    onCheckedChanged: {
                        Config.options.bar.showBackground = checked;
                    }
                    StyledToolTip {
                        content: Translation.tr("Note: turning off can hurt readability")
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Buttons")
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr("Screen snip")
                    checked: Config.options.bar.utilButtons.showScreenSnip
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showScreenSnip = checked;
                    }
                }
                ConfigSwitch {
                    text: Translation.tr("Color picker")
                    checked: Config.options.bar.utilButtons.showColorPicker
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showColorPicker = checked;
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr("Mic toggle")
                    checked: Config.options.bar.utilButtons.showMicToggle
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showMicToggle = checked;
                    }
                }
                ConfigSwitch {
                    text: Translation.tr("Keyboard toggle")
                    checked: Config.options.bar.utilButtons.showKeyboardToggle
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showKeyboardToggle = checked;
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr("Dark/Light toggle")
                    checked: Config.options.bar.utilButtons.showDarkModeToggle
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showDarkModeToggle = checked;
                    }
                }
                ConfigSwitch {
                    text: Translation.tr("Performance Profile toggle")
                    checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Workspaces")
            tooltip: Translation.tr("Tip: Hide icons and always show numbers for\nthe classic illogical-impulse experience")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: Translation.tr('Show app icons')
                    checked: Config.options.bar.workspaces.showAppIcons
                    onCheckedChanged: {
                        Config.options.bar.workspaces.showAppIcons = checked;
                    }
                }
                ConfigSwitch {
                    text: Translation.tr('Tint app icons')
                    checked: Config.options.bar.workspaces.monochromeIcons
                    onCheckedChanged: {
                        Config.options.bar.workspaces.monochromeIcons = checked;
                    }
                }
            }
            ConfigSwitch {
                text: Translation.tr('Always show numbers')
                checked: Config.options.bar.workspaces.alwaysShowNumbers
                onCheckedChanged: {
                    Config.options.bar.workspaces.alwaysShowNumbers = checked;
                }
            }
            ConfigSpinBox {
                text: Translation.tr("Workspaces shown")
                value: Config.options.bar.workspaces.shown
                from: 1
                to: 30
                stepSize: 1
                onValueChanged: {
                    Config.options.bar.workspaces.shown = value;
                }
            }
            ConfigSpinBox {
                text: Translation.tr("Number show delay when pressing Super (ms)")
                value: Config.options.bar.workspaces.showNumberDelay
                from: 0
                to: 1000
                stepSize: 50
                onValueChanged: {
                    Config.options.bar.workspaces.showNumberDelay = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Tray")
            
            ConfigSwitch {
                text: Translation.tr('Tint icons')
                checked: Config.options.bar.tray.monochromeIcons
                onCheckedChanged: {
                    Config.options.bar.tray.monochromeIcons = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Weather")
            ConfigSwitch {
                text: Translation.tr("Enable")
                checked: Config.options.bar.weather.enable
                onCheckedChanged: {
                    Config.options.bar.weather.enable = checked;
                }
            }
        }
    }

    ContentSection {
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
        title: Translation.tr("Sidebars")
        ConfigSwitch {
            text: Translation.tr('Keep right sidebar loaded')
            checked: Config.options.sidebar.keepRightSidebarLoaded
            onCheckedChanged: {
                Config.options.sidebar.keepRightSidebarLoaded = checked;
            }
            StyledToolTip {
                content: Translation.tr("When enabled keeps the content of the right sidebar loaded to reduce the delay when opening,\nat the cost of around 15MB of consistent RAM usage. Delay significance depends on your system's performance.\nUsing a different kernel might help with this delay")
            }
        }
    }

    ContentSection {
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
}
