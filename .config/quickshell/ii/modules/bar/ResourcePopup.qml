import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    hoverTarget: mouseArea

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        // Header
        RowLayout {
            id: header
            spacing: 5

            MaterialSymbol {
                fill: 0
                font.weight: Font.Medium
                text: root.tooltipHeaderIcon
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                text: root.tooltipHeaderText
                font {
                    weight: Font.Medium
                    pixelSize: Appearance.font.pixelSize.normal
                }
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        // Info rows
        Repeater {
            model: root.tooltipData
            delegate: RowLayout {
                spacing: 5
                Layout.fillWidth: true

                MaterialSymbol {
                    text: modelData.icon
                    color: Appearance.colors.colOnSurfaceVariant
                    iconSize: Appearance.font.pixelSize.large
                }
                StyledText {
                    text: modelData.label
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    visible: modelData.value !== ""
                    color: Appearance.colors.colOnSurfaceVariant
                    text: modelData.value
                }
            }
        }
    }
}