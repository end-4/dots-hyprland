pragma ComponentBehavior: Bound
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
    property bool expanded: notification.actions.length > 0
    property string groupExpandControlMessage: ""
    signal groupExpandToggle
    hoverEnabled: true

    function dismiss() {
        Qt.callLater(() => {
            Notifications.discardNotification(root.notification?.notificationId);
        });
        removeAnimation.start();
    }

    WNotificationDismissAnim {
        id: removeAnimation
        target: root
    }

    implicitHeight: contentItem.implicitHeight
    implicitWidth: contentItem.implicitWidth

    Behavior on implicitHeight {
        animation: Looks.transition.enter.createObject(this)
    }

    property real dragDismissThreshold: 100
    drag {
        axis: Drag.XAxis
        target: contentItem
        minimumX: 0
        onActiveChanged: {
            if (drag.active)
                return;
            if (contentItem.x > root.dragDismissThreshold) {
                root.dismiss();
            } else {
                contentItem.x = 0;
            }
        }
    }

    Rectangle {
        id: contentItem
        width: parent.width
        color: Looks.colors.bgPanelBody
        radius: Looks.radius.medium
        property real padding: 12
        implicitHeight: notificationContent.implicitHeight + padding * 2
        implicitWidth: notificationContent.implicitWidth + padding * 2
        border.width: 1
        border.color: ColorUtils.applyAlpha(Looks.colors.ambientShadow, 0.1)

        Behavior on x {
            animation: Looks.transition.enter.createObject(this)
        }

        ColumnLayout {
            id: notificationContent
            anchors.fill: parent
            anchors.margins: contentItem.padding
            spacing: 19

            // Header
            SingleNotificationHeader {
                Layout.fillWidth: true
            }

            // Content
            Item {
                id: actualContent
                Layout.fillWidth: true
                Layout.fillHeight: true
                property real spacing: 16
                implicitHeight: Math.max(contentColumn.implicitHeight, imageLoader.height)
                implicitWidth: contentColumn.implicitWidth

                Loader {
                    id: imageLoader
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    active: root.notification.image != ""
                    sourceComponent: StyledImage {
                        readonly property int size: 48
                        width: size
                        height: size
                        sourceSize.width: size
                        sourceSize.height: size
                        source: root.notification.image
                        fillMode: Image.PreserveAspectFit
                    }
                }

                ColumnLayout {
                    id: contentColumn
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    spacing: 3

                    SummaryText {
                        id: summaryText
                        Layout.leftMargin: imageLoader.active ? imageLoader.width + actualContent.spacing : 0
                    }
                    BodyText {
                        Layout.leftMargin: imageLoader.active ? imageLoader.width + actualContent.spacing : 0
                        // onLineLaidOut: (line) => {
                        //     if (!imageLoader.active) return;
                        //     const dodgeDistance = imageLoader.width + actualContent.spacing;
                        //     // print(line.y, dodgeDistance)
                        //     if (summaryText.height + line.y > dodgeDistance) {
                        //         line.x -= dodgeDistance;
                        //         line.width += dodgeDistance;
                        //     }
                        // }
                    }
                }
            }

            // Actions
            ActionsRow {
                Layout.fillWidth: true
            }

            // "+1 notifications" button
            GroupExpandButton {
                Layout.bottomMargin: 2
            }
        }
    }

    component SingleNotificationHeader: RowLayout {
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
            onClicked: root.dismiss()
        }
    }

    component ActionsRow: RowLayout {
        visible: root.expanded && root.notification.actions.length > 0
        uniformCellSizes: true
        Repeater {
            id: actionRepeater
            model: root.notification.actions
            delegate: WBorderedButton {
                id: actionButton
                Layout.fillHeight: true
                required property var modelData
                Layout.fillWidth: true
                verticalPadding: 16
                horizontalPadding: 12
                text: modelData.text
                implicitHeight: actionButtonText.implicitHeight + verticalPadding * 2
                contentItem: WText {
                    id: actionButtonText
                    text: actionButton.text
                    font.pixelSize: Looks.font.pixelSize.large
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
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
        text: {
            if (root.expanded)
                return `<style>img{max-width:${summaryText.width}px; align: right}</style>` + `${NotificationUtils.processNotificationBody(root.notification.body, root.notification.appName || root.notification.summary).replace(/\n/g, "<br/>")}`;
            return NotificationUtils.processNotificationBody(root.notification.body, root.notification.appName || root.notification.summary).replace(/\n/g, "<br/>");
        }
        color: Looks.colors.subfg
        textFormat: root.expanded ? Text.RichText : Text.StyledText
        onLinkActivated: link => {
            Qt.openUrlExternally(link);
            GlobalStates.sidebarRightOpen = false;
        }
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

    component GroupExpandButton: AcrylicButton {
        id: groupExpandButton
        visible: root.groupExpandControlMessage !== ""
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
