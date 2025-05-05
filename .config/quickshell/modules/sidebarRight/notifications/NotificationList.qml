import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt5Compat.GraphicalEffects
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

        function onDiscardAll() {
            for (let i = notificationWidgetList.length - 1; i >= 0; i--) {
                const widget = notificationWidgetList[i];
                if (widget && widget.notificationObject) {
                    widget.destroyWithAnimation();
                }
            }
            notificationWidgetList = [];
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
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: flickable.width
                height: flickable.height
                radius: Appearance.rounding.normal
            }
        }

        ColumnLayout { // Scrollable window content
            id: columnLayout
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0 // The widgets themselves have margins for spacing

            // Notifications are added by the above signal handlers
        }
    }

    // Placeholder when list is empty
    Item {
        anchors.fill: flickable

        visible: opacity > 0
        opacity: (root.notificationWidgetList.length === 0) ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.menuDecel.duration
                easing.type: Appearance.animation.menuDecel.type
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                iconSize: 55
                color: Appearance.m3colors.m3outline
                text: "notifications_active"
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3outline
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("No notifications")
            }
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
            text: `${notificationWidgetList.length} notification${notificationWidgetList.length > 1 ? "s" : ""}`

            opacity: notificationWidgetList.length > 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Appearance.animation.elementMove.type
                    easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                }
            }
        }

        Item { Layout.fillWidth: true }

        NotificationStatusButton {
            Layout.alignment: Qt.AlignVCenter
            Layout.margins: 5
            Layout.topMargin: 10
            buttonIcon: "clear_all"
            buttonText: qsTr("Clear")
            onClicked: () => {
                Notifications.discardAllNotifications()
            }
        }
    }
}