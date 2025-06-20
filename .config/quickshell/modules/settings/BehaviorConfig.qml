import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"

ContentPage {
    ContentSection {
        title: "Policies"

        ConfigRow {
            ColumnLayout { // Weeb policy
                StyledText {
                    text: "Weeb"
                    color: Appearance.colors.colSubtext
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
                StyledText {
                    text: "AI"
                    color: Appearance.colors.colSubtext
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
}