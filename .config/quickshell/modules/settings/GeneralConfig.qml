import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../services/"
import "../../modules/common/"
import "../../modules/common/widgets/"

ContentPage {
    forceWidth: true
    ContentSection {
        title: "Policies"

        ConfigRow {
            ColumnLayout { // Weeb policy
                ContentSubsectionLabel {
                    text: "Weeb"
                }
                ConfigSelectionArray {
                    currentValue: ConfigOptions.policies.weeb
                    configOptionName: "policies.weeb"
                    onSelected: (newValue) => {
                        ConfigLoader.setConfigValueAndSave("policies.weeb", newValue);
                    }
                    options: [
                        { displayName: "No", value: 0 },
                        { displayName: "Yes", value: 1 },
                        { displayName: "Closet", value: 2 }
                    ]
                }
            }

            ColumnLayout { // AI policy
                ContentSubsectionLabel {
                    text: "AI"
                }
                ConfigSelectionArray {
                    currentValue: ConfigOptions.policies.ai
                    configOptionName: "policies.ai"
                    onSelected: (newValue) => {
                        ConfigLoader.setConfigValueAndSave("policies.ai", newValue);
                    }
                    options: [
                        { displayName: "No", value: 0 },
                        { displayName: "Yes", value: 1 },
                        { displayName: "Local only", value: 2 }
                    ]
                }
            }
        }
    }
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
    }
    ContentSection {
        title: "AI"
        MaterialTextField {
            id: systemPromptField
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
        title: "Bar"

        ContentSubsection {
            title: "Appearance"
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: 'Borderless'
                    checked: ConfigOptions.bar.borderless
                    onCheckedChanged: {
                        ConfigLoader.setConfigValueAndSave("bar.borderless", checked);
                    }
                }
                ConfigSwitch {
                    text: 'Show background'
                    checked: ConfigOptions.bar.showBackground
                    onCheckedChanged: {
                        ConfigLoader.setConfigValueAndSave("bar.showBackground", checked);
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
                    checked: ConfigOptions.bar.utilButtons.showScreenSnip
                    onCheckedChanged: {
                        ConfigLoader.setConfigValueAndSave("bar.utilButtons.showScreenSnip", checked);
                    }
                }
                ConfigSwitch {
                    text: "Color picker"
                    checked: ConfigOptions.bar.utilButtons.showColorPicker
                    onCheckedChanged: {
                        ConfigLoader.setConfigValueAndSave("bar.utilButtons.showColorPicker", checked);
                    }
                }
            }
            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: "Mic toggle"
                    checked: ConfigOptions.bar.utilButtons.showMicToggle
                    onCheckedChanged: {
                        ConfigLoader.setConfigValueAndSave("bar.utilButtons.showMicToggle", checked);
                    }
                }
                ConfigSwitch {
                    text: "Keyboard toggle"
                    checked: ConfigOptions.bar.utilButtons.showKeyboardToggle
                    onCheckedChanged: {
                        ConfigLoader.setConfigValueAndSave("bar.utilButtons.showKeyboardToggle", checked);
                    }
                }
            }
        }

    }
}