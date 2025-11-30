import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks

MouseArea {
    id: root

    required property var notificationGroup
    readonly property var notifications: notificationGroup?.notifications ?? []
    property bool expanded: false

    implicitWidth: contentLayout.implicitWidth
    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 4

        GroupHeader {
            id: notifHeader
            Layout.fillWidth: true
            Layout.margins: 11
        }

        ListView {
            Layout.fillWidth: true
            implicitWidth: notifHeader.implicitWidth
            implicitHeight: contentHeight
            interactive: false
            spacing: 4
            model: ScriptModel {
                values: root.expanded ? root.notifications.slice().reverse() : root.notifications.slice(-1)
                objectProp: "notificationId"
            }
            delegate: WSingleNotification {
                required property int index
                required property var modelData
                width: ListView.view.width
                notification: modelData
                groupExpandControlMessage: {
                    if (root.notifications.length <= 1) return "";
                    if (!root.expanded) return Translation.tr("+%1 notifications").arg(root.notifications.length - 1);
                    if (index === root.notifications.length - 1) return Translation.tr("See fewer");
                    return "";
                }
                onGroupExpandToggle: {
                    root.expanded = !root.expanded;
                }
            }
        }
    }

    component GroupHeader: MouseArea {
        id: headerMouseArea
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        implicitWidth: appHeader.implicitWidth
        implicitHeight: appHeader.implicitHeight

        RowLayout {
            id: appHeader
            anchors.fill: parent
            spacing: 7

            WNotificationAppIcon {
                Layout.alignment: Qt.AlignVCenter
                icon: root.notificationGroup?.appIcon ?? ""
            }

            WText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                text: root.notificationGroup?.appName ?? ""
            }

            // NotificationHeaderButton { // TODO: More notification functionality needed so we can have this button
            //     visible: headerMouseArea.containsMouse
            //     Layout.leftMargin: 25
            //     Layout.rightMargin: 25
            //     icon.name: "more-horizontal"
            // }

            NotificationHeaderButton {
                visible: headerMouseArea.containsMouse
                Layout.rightMargin: 3
                icon.name: "dismiss"
                onClicked: {
                    root.notifications.forEach(notif => {
                        Qt.callLater(() => {
                            Notifications.discardNotification(notif.notificationId);
                        });
                    });
                }
            }
        }
    }
}
