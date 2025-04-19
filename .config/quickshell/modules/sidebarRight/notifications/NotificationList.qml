import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

Item {
    id: root
    property Component notifComponent: NotificationWidget {}
    property list<NotificationWidget> notificationWidgetList: []

    // Signal handlers to add/remove notifications
    Connections {
        target: Notifications
        function onInitDone() {
            // notificationRepeater.model = Notifications.list.slice().reverse()
            Notifications.list.slice().reverse().forEach((notification) => {
                const notif = root.notifComponent.createObject(columnLayout, { notificationObject: notification });
                notificationWidgetList.push(notif)
            })
        }
        function onNotify(notification) {
            // notificationRepeater.model = [notification, ...notificationRepeater.model]
            const notif = root.notifComponent.createObject(columnLayout, { notificationObject: notification });
            notificationWidgetList.unshift(notif)

            // Remove stuff from t he column, add back
            for (let i = 0; i < notificationWidgetList.length; i++) {
                if (notificationWidgetList[i].parent === columnLayout) {
                    notificationWidgetList[i].parent = null;
                }
            }

            // Add notification widgets to the column
            for (let i = 0; i < notificationWidgetList.length; i++) {
                if (notificationWidgetList[i].parent === null) {
                    notificationWidgetList[i].parent = columnLayout;
                }
            }
        }
        function onDiscard(id) {
            for (let i = notificationWidgetList.length - 1; i >= 0; i--) {
                const widget = notificationWidgetList[i];
                if (widget && widget.notificationObject && widget.notificationObject.id === id) {
                    widget.destroyWithAnimation();
                    notificationWidgetList.splice(i, 1);
                }
            }
        }
    }

    Flickable { // Scrollable window
        id: flickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        contentHeight: columnLayout.height
        clip: true

        ColumnLayout { // Scrollable window content
            id: columnLayout
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0 // The widgets themselves have margins for spacing

            // Notifications are added by the above signal handlers
        }
    }

    RowLayout {
        id: statusRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        StyledText {
            Layout.margins: 10
            Layout.bottomMargin: 5
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: `${notificationWidgetList.length} Notifications`
        }
    }
}