import "root:/modules/common"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "./notification_utils.js" as NotificationUtils

Item {
    id: root
    property var notificationObject
    property bool expanded: false
    property bool enableAnimation: true
    property int notificationListSpacing: 5
    property bool ready: false

    Layout.fillWidth: true
    clip: true

    // implicitHeight: notificationRowLayout.implicitHeight
    implicitHeight: ready ? notificationRowLayout.implicitHeight + notificationListSpacing : 0
    Behavior on implicitHeight {
        enabled: enableAnimation
        NumberAnimation {
            duration: Appearance.animation.elementDecel.duration
            easing.type: Appearance.animation.elementDecel.type
        }
    }

    Component.onCompleted: {
        root.ready = true
    }

    function fancyDestroy() {
        implicitHeight = 0
        notificationRowWrapper.anchors.top = undefined
        notificationRowWrapper.anchors.bottom = root.bottom
        destroyTimer.start()
    }

    Timer {
        id: destroyTimer
        interval: Appearance.animation.elementDecel.duration
        repeat: false
        onTriggered: {
            root.destroy()
        }
    }

    MouseArea { // Middle click to close
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button == Qt.MiddleButton) {
                Notifications.discardNotification(notificationObject.id)
            }
        }
    }

    // Background
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: notificationListSpacing
        color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
            Appearance.m3colors.m3secondaryContainer : Appearance.colors.colLayer2
        radius: Appearance.rounding.normal
    }


    Item {
        id: notificationRowWrapper
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: notificationRowLayout.implicitHeight + notificationListSpacing
        RowLayout {
            id: notificationRowLayout

            anchors.left: parent.left
            anchors.right: parent.right
            // anchors.top: parent.top
            anchors.bottom: parent.bottom
            Rectangle { // App icon
                id: iconRectangle
                implicitWidth: 47
                implicitHeight: 47
                Layout.leftMargin: 10
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: false
                radius: Appearance.rounding.full
                color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
                    Appearance.m3colors.m3secondary : Appearance.m3colors.m3secondaryContainer
                MaterialSymbol {
                    visible: notificationObject.appIcon == ""
                    text: NotificationUtils.guessMessageType(notificationObject.summary)
                    anchors.fill: parent
                    color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
                        Appearance.m3colors.m3onSecondary : Appearance.m3colors.m3onSecondaryContainer
                    font.pixelSize: 27
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                IconImage {
                    visible: notificationObject.appIcon != ""
                    anchors.centerIn: parent
                    implicitSize: 33
                    asynchronous: true
                    source: Quickshell.iconPath(notificationObject.appIcon)
                }
            }
            ColumnLayout { // Notification content
                spacing: 0
                Layout.fillWidth: true

                RowLayout { // Row of summary, time and expand button
                    Layout.topMargin: 10
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    Layout.fillWidth: true

                    StyledText { // Summary
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer2
                        text: notificationObject.summary
                        wrapMode: expanded ? Text.Wrap : Text.NoWrap
                        elide: Text.ElideRight
                    }

                    Item { Layout.fillWidth: true }

                    StyledText { // Time
                        id: notificationTimeText
                        Layout.fillWidth: false
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignLeft
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3outline
                        text: NotificationUtils.getFriendlyNotifTimeString(notificationObject.time)

                        Connections {
                            target: DateTime
                            function onTimeChanged() {
                                notificationTimeText.text = NotificationUtils.getFriendlyNotifTimeString(notificationObject.time)
                            }
                        }
                    }

                    Button { // Expand button
                        Layout.alignment: Qt.AlignVCenter
                        id: expandButton
                        implicitWidth: 22
                        implicitHeight: 22

                        PointingHandInteraction{}
                        onClicked: {
                            root.enableAnimation = true
                            root.expanded = !root.expanded
                        }

                        background: Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.full
                            color: (expandButton.down) ? Appearance.colors.colLayer2Active : (expandButton.hovered ? Appearance.colors.colLayer2Hover : Appearance.transparentize(Appearance.colors.colLayer2, 1))

                            Behavior on color {
                                ColorAnimation {
                                    duration: Appearance.animation.elementDecel.duration
                                    easing.type: Appearance.animation.elementDecel.type
                                }

                            }

                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: expanded ? "keyboard_arrow_up" : "keyboard_arrow_down"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer2
                        }

                    }
                }

                StyledText { // Notification body
                    Layout.fillWidth: true
                    Layout.bottomMargin: 10
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    clip: true
                    wrapMode: expanded ? Text.Wrap : Text.NoWrap
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.small
                    horizontalAlignment: Text.AlignLeft
                    color: Appearance.m3colors.m3outline
                    // textFormat: Text.MarkdownText
                    text: notificationObject.body   
                }
            }
        }
    }
}
