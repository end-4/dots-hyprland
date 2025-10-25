import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts


StyledPopup {
    id: root

    ColumnLayout {
        id: columnLayout
        Layout.alignment: Qt.AlignVCenter
        anchors.centerIn: parent
        
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            MaterialSymbol {
                fill: 0
                font.weight: Font.Medium
                text: "refresh"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer2
                text: Translation.tr("Last update:")
            }

            StyledText {
                Layout.fillWidth: true
                text: SystemUpdates.lastFetch
                font {
                    weight: Font.Medium
                    pixelSize: Appearance.font.pixelSize.normal
                }
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }
}
