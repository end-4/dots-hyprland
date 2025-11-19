import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

WBarAttachedPanelContent {
    id: root

    contentItem: StackView {
        implicitWidth: currentItem.implicitWidth
        implicitHeight: currentItem.implicitHeight

        initialItem: ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            ActionCenterBody {}

            Rectangle {
                Layout.fillHeight: false
                Layout.fillWidth: true
                color: Looks.colors.bgPanelSeparator
                implicitHeight: 1
            }

            ActionCenterFooter {}
        }

        Component.onCompleted: {
            ActionCenterContext.stackView = this
        }
    }
}
