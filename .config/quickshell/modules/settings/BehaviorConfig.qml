import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"

ContentPage {
    ContentSection {
        title: "Policies"

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 15
            ColumnLayout { // Weeb policy
                StyledText {
                    text: "Weeb"
                    color: Appearance.colors.colSubtext
                }
                ButtonGroup {
                    id: weebPolicyBtnGroup
                    property int selectedPolicy: ConfigOptions.policies.weeb
                    spacing: 2
                    SelectionGroupButton {
                        property int value: 0
                        leftmost: true
                        buttonText: "No"
                        toggled: (weebPolicyBtnGroup.selectedPolicy === value)
                        onClicked: {
                            ConfigLoader.setConfigValueAndSave("policies.weeb", value);
                        }
                    }
                    SelectionGroupButton {
                        property int value: 1
                        buttonText: "Yes"
                        toggled: (weebPolicyBtnGroup.selectedPolicy === value)
                        onClicked: {
                            ConfigLoader.setConfigValueAndSave("policies.weeb", value);
                        }
                    }
                    SelectionGroupButton {
                        property int value: 2
                        rightmost: true
                        buttonText: "Closet"
                        toggled: (weebPolicyBtnGroup.selectedPolicy === value)
                        onClicked: {
                            ConfigLoader.setConfigValueAndSave("policies.weeb", value);
                        }
                        StyledToolTip {
                            content: "The Anime tab on the left sidebar would still\nbe available, but its tab button won't show"
                        }
                    }
                }
            }
            ColumnLayout { // AI policy
                StyledText {
                    text: "AI"
                    color: Appearance.colors.colSubtext
                }
                ButtonGroup {
                    id: aiPolicyBtnGroup
                    property int selectedPolicy: ConfigOptions.policies.ai
                    spacing: 2
                    SelectionGroupButton {
                        property int value: 0
                        leftmost: true
                        buttonText: "No"
                        toggled: (aiPolicyBtnGroup.selectedPolicy === value)
                        onClicked: {
                            ConfigLoader.setConfigValueAndSave("policies.ai", value);
                        }
                    }
                    SelectionGroupButton {
                        property int value: 1
                        buttonText: "Yes"
                        toggled: (aiPolicyBtnGroup.selectedPolicy === value)
                        onClicked: {
                            ConfigLoader.setConfigValueAndSave("policies.ai", value);
                        }
                    }
                    SelectionGroupButton {
                        property int value: 2
                        rightmost: true
                        buttonText: "Local only"
                        toggled: (aiPolicyBtnGroup.selectedPolicy === value)
                        onClicked: {
                            ConfigLoader.setConfigValueAndSave("policies.ai", value);
                        }
                    }
                }
            }
        }
    }
}