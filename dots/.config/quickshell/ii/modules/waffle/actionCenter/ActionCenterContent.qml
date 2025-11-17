import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    contentItem: ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        ActionCenterBody {
            topLeftRadius: root.border.radius - root.border.border.width
            topRightRadius: topLeftRadius
        }

        Rectangle {
            Layout.fillHeight: false
            Layout.fillWidth: true
            color: Looks.colors.bgPanelSeparator
            implicitHeight: 1
        }

        ActionCenterFooter {
            bottomLeftRadius: root.border.radius - root.border.border.width
            bottomRightRadius: bottomLeftRadius
        }
    }
}
