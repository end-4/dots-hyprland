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
            checked: ConfigOptions.audio.protection.enable
            onCheckedChanged: {
                ConfigLoader.setConfigValueAndSave("audio.protection.enable", checked);
            }
            StyledToolTip {
                content: "Prevents abrupt increments and restricts volume limit"
            }
        }
        ConfigRow {
            // uniform: true
            ConfigSpinBox {
                text: "Max allowed increase"
                value: ConfigOptions.audio.protection.maxAllowedIncrease
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    ConfigLoader.setConfigValueAndSave("audio.protection.maxAllowedIncrease", value);
                }
            }
            ConfigSpinBox {
                text: "Volume limit"
                value: ConfigOptions.audio.protection.maxAllowed
                from: 0
                to: 100
                stepSize: 2
                onValueChanged: {
                    ConfigLoader.setConfigValueAndSave("audio.protection.maxAllowed", value);
                }
            }
        }
    }
    ContentSection {
        title: "AI"
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "System prompt"
            text: ConfigOptions.ai.systemPrompt
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                ConfigLoader.setConfigValueAndSave("ai.systemPrompt", text);
            }
        }
    }

    ContentSection {
        title: "Battery"

        ConfigRow {
            uniform: true
            ConfigSpinBox {
                text: "Low warning"
                value: ConfigOptions.battery.low
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    ConfigLoader.setConfigValueAndSave("battery.low", value);
                }
            }
            ConfigSpinBox {
                text: "Critical warning"
                value: ConfigOptions.battery.critical
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    ConfigLoader.setConfigValueAndSave("battery.critical", value);
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                text: "Automatic suspend"
                checked: ConfigOptions.battery.automaticSuspend
                onCheckedChanged: {
                    ConfigLoader.setConfigValueAndSave("battery.automaticSuspend", checked);
                }
                StyledToolTip {
                    content: "Automatically suspends the system when battery is low"
                }
            }
            ConfigSpinBox {
                text: "Suspend at"
                value: ConfigOptions.battery.suspend
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    ConfigLoader.setConfigValueAndSave("battery.suspend", value);
                }
            }
        }
    }

    ContentSection {
        title: "Networking"
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "User agent (for services that require it)"
            text: ConfigOptions.networking.userAgent
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                ConfigLoader.setConfigValueAndSave("networking.userAgent", text);
            }
        }
    }

    ContentSection {
        title: "Resources"
        ConfigSpinBox {
            text: "Polling interval (ms)"
            value: ConfigOptions.resources.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                ConfigLoader.setConfigValueAndSave("resources.updateInterval", value);
            }
        }
    }

}