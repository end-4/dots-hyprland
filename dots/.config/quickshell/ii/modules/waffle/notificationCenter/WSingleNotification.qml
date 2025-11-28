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
    property string groupExpandControlMessage: ""
    signal groupExpandToggle
    hoverEnabled: true

    implicitHeight: contentItem.implicitHeight
    implicitWidth: contentItem.implicitWidth

    Behavior on implicitHeight {
        animation: Looks.transition.enter.createObject(this)
    }

    Rectangle {
        id: contentItem
        anchors.fill: parent
        color: Looks.colors.bgPanelBody
        radius: Looks.radius.medium
        property real padding: 12
        implicitHeight: notificationContent.implicitHeight + padding * 2
        implicitWidth: notificationContent.implicitWidth + padding * 2
        border.width: 1
        border.color: ColorUtils.applyAlpha(Looks.colors.ambientShadow, 0.1)

        ColumnLayout {
            id: notificationContent
            anchors.fill: parent
            anchors.margins: contentItem.padding
            spacing: 19

            RowLayout {
                Layout.fillWidth: true

                ExpandButton {
                    Layout.topMargin: -2
                }

                Item {
                    Layout.fillWidth: true
                }

                NotificationHeaderButton {
                    Layout.rightMargin: 4
                    opacity: root.containsMouse ? 1 : 0
                    icon.name: "dismiss"
                    implicitSize: 12
                    onClicked: {
                        Qt.callLater(() => {
                            Notifications.discardNotification(root.notification?.notificationId);
                        });
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                SummaryText {}
                BodyText {}
            }

            AcrylicButton {
                id: groupExpandButton
                visible: root.groupExpandControlMessage !== ""
                Layout.bottomMargin: 2
                horizontalPadding: 10
                implicitHeight: 24
                implicitWidth: expandButtonText.implicitWidth + horizontalPadding * 2
                onClicked: root.groupExpandToggle()
                contentItem: Item {
                    WText {
                        id: expandButtonText
                        anchors.centerIn: parent
                        text: root.groupExpandControlMessage
                    }
                }
            }
        }
    }

    component SummaryText: WText {
        Layout.fillWidth: true
        elide: Text.ElideRight
        text: root.notification?.summary
        font.pixelSize: Looks.font.pixelSize.large
    }

    component BodyText: WText {
        Layout.fillWidth: true
        Layout.fillHeight: true
        elide: Text.ElideRight
        verticalAlignment: Text.AlignTop
        wrapMode: Text.Wrap
        maximumLineCount: root.expanded ? 100 : 1
        text: root.notification?.body
        color: Looks.colors.subfg
    }

    component ExpandButton: NotificationHeaderButton {
        id: expandButton
        implicitWidth: expandButtonContent.implicitWidth
        onClicked: root.expanded = !root.expanded

        contentItem: Item {
            id: expandButtonContent
            implicitWidth: expandButtonRow.implicitWidth
            implicitHeight: expandButtonRow.implicitHeight
            RowLayout {
                id: expandButtonRow
                anchors.centerIn: parent
                spacing: 8
                WText {
                    color: expandButton.colForeground
                    text: NotificationUtils.getFriendlyNotifTimeString(root.notification?.time)
                }
                FluentIcon {
                    Layout.rightMargin: 12
                    icon: "chevron-down"
                    implicitSize: 18
                    rotation: root.expanded ? -180 : 0
                    color: expandButton.colForeground
                    Behavior on rotation {
                        animation: Looks.transition.rotate.createObject(this)
                    }
                }
            }
        }
    }
}
