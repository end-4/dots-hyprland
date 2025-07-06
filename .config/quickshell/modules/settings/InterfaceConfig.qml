import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"

ContentPage {
    forceWidth: true
    ContentSection {
        title: "Policies"

        ConfigRow {
            ColumnLayout {
                // Weeb policy
                ContentSubsectionLabel {
                    text: "Weeb"
                }
                ConfigSelectionArray {
                    currentValue: Config.options.policies.weeb
                    configOptionName: "policies.weeb"
                    onSelected: newValue => {
                        Config.options.policies.weeb = newValue;
                    }
                    options: [
                        {
                            displayName: "No",
                            value: 0
                        },
                        {
                            displayName: "Yes",
                            value: 1
                        },
                        {
                            displayName: "Closet",
                            value: 2
                        }
                    ]
                }
            }

            ColumnLayout {
                // AI policy
                ContentSubsectionLabel {
                    text: "AI"
                }
                ConfigSelectionArray {
                    currentValue: Config.options.policies.ai
                    configOptionName: "policies.ai"
                    onSelected: newValue => {
                        Config.options.policies.ai = newValue;
                    }
                    options: [
                        {
                            displayName: "No",
                            value: 0
                        },
                        {
                            displayName: "Yes",
                            value: 1
                        },
                        {
                            displayName: "Local only",
                            value: 2
                        }
                    ]
                }
            }
        }
    }

    ContentSection {
        title: "Bar"

        ConfigSelectionArray {
            currentValue: Config.options.bar.cornerStyle
            configOptionName: "bar.cornerStyle"
            onSelected: newValue => {
                Config.options.bar.cornerStyle = newValue;
            }
            options: [
                {
                    displayName: "Hug",
                    value: 0
                },
                {
                    displayName: "Float",
                    value: 1
                },
                {
                    displayName: "Plain rectangle",
                    value: 2
                }
            ]
        }

        ContentSubsection {
            title: "Appearance"
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: 'Borderless'
                    checked: Config.options.bar.borderless
                    onCheckedChanged: {
                        Config.options.bar.borderless = checked;
                    }
                }
                ConfigSwitch {
                    text: 'Show background'
                    checked: Config.options.bar.showBackground
                    onCheckedChanged: {
                        Config.options.bar.showBackground = checked;
                    }
                    StyledToolTip {
                        content: "Note: turning off can hurt readability"
                    }
                }
            }
        }

        ContentSubsection {
            title: "Buttons"
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: "Screen snip"
                    checked: Config.options.bar.utilButtons.showScreenSnip
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showScreenSnip = checked;
                    }
                }
                ConfigSwitch {
                    text: "Color picker"
                    checked: Config.options.bar.utilButtons.showColorPicker
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showColorPicker = checked;
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: "Mic toggle"
                    checked: Config.options.bar.utilButtons.showMicToggle
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showMicToggle = checked;
                    }
                }
                ConfigSwitch {
                    text: "Keyboard toggle"
                    checked: Config.options.bar.utilButtons.showKeyboardToggle
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showKeyboardToggle = checked;
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: "Dark/Light toggle"
                    checked: Config.options.bar.utilButtons.showDarkModeToggle
                    onCheckedChanged: {
                        Config.options.bar.utilButtons.showDarkModeToggle = checked;
                    }
                }
                ConfigSwitch {
                    opacity: 0
                    enabled: false
                }
            }
        }

        ContentSubsection {
            title: "Workspaces"
            tooltip: "Tip: Hide icons and always show numbers for\nthe classic illogical-impulse experience"

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: 'Show app icons'
                    checked: Config.options.bar.workspaces.showAppIcons
                    onCheckedChanged: {
                        Config.options.bar.workspaces.showAppIcons = checked;
                    }
                }
                ConfigSwitch {
                    text: 'Always show numbers'
                    checked: Config.options.bar.workspaces.alwaysShowNumbers
                    onCheckedChanged: {
                        Config.options.bar.workspaces.alwaysShowNumbers = checked;
                    }
                }
            }
            ConfigSpinBox {
                text: "Workspaces shown"
                value: Config.options.bar.workspaces.shown
                from: 1
                to: 30
                stepSize: 1
                onValueChanged: {
                    Config.options.bar.workspaces.shown = value;
                }
            }
            ConfigSpinBox {
                text: "Number show delay when pressing Super (ms)"
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
            title: "Weather"
            ConfigSwitch {
                text: "Enable"
                checked: Config.options.bar.weather.enable
                onCheckedChanged: {
                    Config.options.bar.weather.enable = checked;
                }
            }
        }
    }

    ContentSection {
        title: "Battery"

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                text: "Low warning"
                value: Config.options.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.battery.low = value;
                }
            }
            ConfigSpinBox {
                text: "Critical warning"
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
                text: "Automatic suspend"
                checked: Config.options.battery.automaticSuspend
                onCheckedChanged: {
                    Config.options.battery.automaticSuspend = checked;
                }
                StyledToolTip {
                    content: "Automatically suspends the system when battery is low"
                }
            }
            ConfigSpinBox {
                text: "Suspend at"
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
        title: "Dock"

        ConfigSwitch {
            text: "Enable"
            checked: Config.options.dock.enable
            onCheckedChanged: {
                Config.options.dock.enable = checked;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: "Hover to reveal"
                checked: Config.options.dock.hoverToReveal
                onCheckedChanged: {
                    Config.options.dock.hoverToReveal = checked;
                }
            }
            ConfigSwitch {
                text: "Pinned on startup"
                checked: Config.options.dock.pinnedOnStartup
                onCheckedChanged: {
                    Config.options.dock.pinnedOnStartup = checked;
                }
            }
        }
    }

    ContentSection {
        title: "Overview"
        ConfigSpinBox {
            text: "Scale (%)"
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
                text: "Rows"
                value: Config.options.overview.rows
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: {
                    Config.options.overview.rows = value;
                }
            }
            ConfigSpinBox {
                text: "Columns"
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
}
