import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

Item {
    Flickable { // Scrollable window
        id: flickable
        anchors.fill: parent
        contentHeight: columnLayout.height
        clip: true

        ColumnLayout { // Scrollable window content
            anchors.left: parent.left
            anchors.right: parent.right
            id: columnLayout

            Repeater {
                model: Notifications.list

                delegate: NotificationWidget {
                    notificationObject: modelData
                }

            }

        }

    }
}