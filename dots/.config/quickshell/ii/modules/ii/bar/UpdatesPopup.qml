import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root

    RowLayout {
        anchors.centerIn: parent
        spacing: 5
        
        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            fill: 0
            text: "update"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnSurfaceVariant
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: Translation.tr("%1 updates available").arg(Updates.count)
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnSurfaceVariant
        }
    }
}
