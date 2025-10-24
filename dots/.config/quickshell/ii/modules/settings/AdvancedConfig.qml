import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "colors"
        title: Translation.tr("Color generation")

        ConfigSwitch {
            buttonIcon: "hardware"
            text: Translation.tr("Shell & utilities")
            checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "tv_options_input_settings"
            text: Translation.tr("Qt apps")
            checked: Config.options.appearance.wallpaperTheming.enableQtApps
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableQtApps = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigSwitch {
            buttonIcon: "terminal"
            text: Translation.tr("Terminal")
            checked: Config.options.appearance.wallpaperTheming.enableTerminal
            onCheckedChanged: {
                Config.options.appearance.wallpaperTheming.enableTerminal = checked;
            }
            StyledToolTip {
                text: Translation.tr("Shell & utilities theming must also be enabled")
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Force dark mode in terminal")
                checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
                onCheckedChanged: {
                     Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode= checked;
                }
                StyledToolTip {
                    text: Translation.tr("Ignored if terminal theming is not enabled")
                }
            }
        }

        ConfigSpinBox {
            icon: "invert_colors"
            text: Translation.tr("Terminal: Harmony (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = value / 100;
            }
        }
        ConfigSpinBox {
            icon: "gradient"
            text: Translation.tr("Terminal: Harmonize threshold")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold = value;
            }
        }
        ConfigSpinBox {
            icon: "format_color_text"
            text: Translation.tr("Terminal: Foreground boost (%)")
            value: Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100
            from: 0
            to: 100
            stepSize: 10
            onValueChanged: {
                Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = value / 100;
            }
        }
    }

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Keybinds Cheatsheet")

        ContentSubsection {
            title: Translation.tr("Super Key Symbol")
            ConfigSelectionArray {
                currentValue: Config.options.appearance.keybinds.superKey
                onSelected: newValue => {
                    Config.options.appearance.keybinds.superKey = newValue;
                }
                // Use a nerdfont to see the icons
                // 0: 󰖳  | 1: 󰌽 | 2: 󰘳 | 3:  | 4: 󰨡
                // 5:  | 6:  | 7: 󰣇 | 8:  | 9: 
                // 10:  | 11:  | 12:  | 13:  | 14: 󱄛
                options: [
                    {
                        displayName: "󰖳",
                        icon: "",
                        value: 0
                    },
                    {
                        displayName: "",
                        icon: "",
                        value: 3
                    },
                    {
                        displayName: "󰨡",
                        icon: "",
                        value: 4
                    },
                    {
                        displayName: "",
                        icon: "",
                        value: 5
                    },
                    {
                        displayName: "󰣇",
                        icon: "",
                        value: 7
                    },
                    {
                        displayName: "",
                        icon: "",
                        value: 12
                    },
                    {
                        displayName: "",
                        icon: "",
                        value: 13
                    },
                    {
                        displayName: "",
                        icon: "",
                        value: 11
                    },
                    {
                        displayName: "",
                        icon: "",
                        value: 10
                    },
                    {
                        displayName: "",
                        icon: "",
                        value: 8
                    },
                    {
                        displayName: "󱄛",
                        icon: "",
                        value: 14
                    },
                    {
                       displayName:  "",
                        icon: "",
                        value: 9
                    },
                    {
                        displayName: "",
                        icon: "",
                        value: 6
                    },
                    {
                        displayName: "󰘳",
                        icon: "",
                        value: 2
                    },
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "󰘵"
            text: Translation.tr("Use macOS-like symbols for mods keys")
            checked: Config.options.appearance.keybinds.useMacSymbol
            onCheckedChanged: {
                Config.options.appearance.keybinds.useMacSymbol = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "󱊶"
            text: Translation.tr("Use symbols for function keys")
            checked: Config.options.appearance.keybinds.useFnSymbol
            onCheckedChanged: {
                Config.options.appearance.keybinds.useFnSymbol = checked;
            }
        }
        ConfigSwitch {
            buttonIcon: "󰍽"
            text: Translation.tr("Use symbols for mouse")
            checked: Config.options.appearance.keybinds.useMouseSymbol
            onCheckedChanged: {
                Config.options.appearance.keybinds.useMouseSymbol = checked;
            }
        }
    }
}
