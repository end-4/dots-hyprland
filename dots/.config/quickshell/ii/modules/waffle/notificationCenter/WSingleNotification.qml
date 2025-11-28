import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks

MouseArea {
    id: root

    required property var notification
    property bool expanded: false

    implicitHeight: contentItem.implicitHeight
    implicitWidth: contentItem.implicitWidth

    Rectangle {
        id: contentItem
        anchors.fill: parent
        color: Looks.colors.bgPanelBody
        radius: Looks.radius.medium
        property real padding: 12
        implicitHeight: notificationContent.implicitHeight + padding * 2
        implicitWidth: notificationContent.implicitWidth + padding * 2
        border.width: 1
        border.color: Looks.applyContentTransparency(Looks.colors.ambientShadow)

        ColumnLayout {
            id: notificationContent
            anchors.fill: parent
            anchors.margins: contentItem.padding

            RowLayout {
                Layout.fillWidth: true
                WText {
                    text: NotificationUtils.getFriendlyNotifTimeString(root.notification?.time)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                WText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.notification.summary
                }
                WText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    maximumLineCount: root.expanded ? 100 : 1
                }
            }
        }
    }
}
