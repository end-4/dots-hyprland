import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"

ContentPage {
    forceWidth: true

    ContentSection {
        title: "Audio"

        ConfigSwitch {
            text: "Earbang protection"
            checked: Config.options.audio.protection.enable
            onCheckedChanged: {
                Config.options.audio.protection.enable = checked;
            }
            StyledToolTip {
                content: "Prevents abrupt increments and restricts volume limit"
            }
        }
        ConfigRow {
            // uniform: true
            ConfigSpinBox {
                text: "Max allowed increase"
                value: Config.options.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowedIncrease = value;
                }
            }
            ConfigSpinBox {
                text: "Volume limit"
                value: Config.options.audio.protection.maxAllowed
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    Config.options.audio.protection.maxAllowed = value;
                }
            }
        }
    }
    ContentSection {
        title: "AI"
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "System prompt"
            text: Config.options.ai.systemPrompt
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Qt.callLater(() => {
                    Config.options.ai.systemPrompt = text;
                });
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
        title: "Networking"
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "User agent (for services that require it)"
            text: Config.options.networking.userAgent
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.networking.userAgent = text;
            }
        }
    }

    ContentSection {
        title: "Resources"
        ConfigSpinBox {
            text: "Polling interval (ms)"
            value: Config.options.resources.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                Config.options.resources.updateInterval = value;
            }
        }
    }

    ContentSection {
        title: "Search"

        ConfigSwitch {
            text: "Use Levenshtein distance-based algorithm instead of fuzzy"
            checked: Config.options.search.sloppy
            onCheckedChanged: {
                Config.options.search.sloppy = checked;
            }
            StyledToolTip {
                content: "Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)"
            }
        }

        ContentSubsection {
            title: "Prefixes"
            ConfigRow {
                uniform: true

                MaterialTextField {
                    Layout.fillWidth: true
                    placeholderText: "Action"
                    text: Config.options.search.prefix.action
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.action = text;
                    }
                }
                MaterialTextField {
                    Layout.fillWidth: true
                    placeholderText: "Clipboard"
                    text: Config.options.search.prefix.clipboard
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.clipboard = text;
                    }
                }
                MaterialTextField {
                    Layout.fillWidth: true
                    placeholderText: "Emojis"
                    text: Config.options.search.prefix.emojis
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Config.options.search.prefix.emojis = text;
                    }
                }
            }
        }
        ContentSubsection {
            title: "Web search"
            MaterialTextField {
                Layout.fillWidth: true
                placeholderText: "Base URL"
                text: Config.options.search.engineBaseUrl
                wrapMode: TextEdit.Wrap
                onTextChanged: {
                    Config.options.search.engineBaseUrl = text;
                }
            }
        }
    }

    ContentSection {
        title: "Time"

        ContentSubsection {
            title: "Format"
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                configOptionName: "time.format"
                onSelected: newValue => {
                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: "24h",
                        value: "hh:mm"
                    },
                    {
                        displayName: "12h am/pm",
                        value: "h:mm ap"
                    },
                    {
                        displayName: "12h AM/PM",
                        value: "h:mm AP"
                    },
                ]
            }
        }
    }
}
