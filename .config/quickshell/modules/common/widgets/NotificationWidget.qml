import "root:/modules/common"
import "root:/services"
import Qt5Compat.GraphicalEffects
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

    implicitHeight: ready ? notificationColumnLayout.implicitHeight + notificationListSpacing : 0
    Behavior on implicitHeight {
        enabled: enableAnimation
        NumberAnimation {
            duration: Appearance.animation.elementDecelFast.duration
            easing.type: Appearance.animation.elementDecelFast.type
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
        interval: Appearance.animation.elementDecelFast.duration
        repeat: false
        onTriggered: {
            root.destroy()
        }
    }

    MouseArea { // Middle click to close
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button == Qt.MiddleButton) 
                Notifications.discardNotification(notificationObject.id);
            else if (mouse.button == Qt.RightButton) 
                root.expanded = !root.expanded;
        }
    }

    // Background
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: notificationListSpacing
        color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
            Appearance.mix(Appearance.m3colors.m3secondaryContainer, Appearance.colors.colLayer2, 0.35) : Appearance.colors.colLayer2
        radius: Appearance.rounding.normal
    }


    Item {
        id: notificationRowWrapper
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: notificationColumnLayout.implicitHeight + notificationListSpacing
        ColumnLayout {
            id: notificationColumnLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            RowLayout {
                id: notificationRowLayout

                Layout.fillWidth: true                    

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
                    color: Appearance.m3colors.m3secondaryContainer
                    MaterialSymbol {
                        visible: notificationObject.appIcon == ""
                        text: (notificationObject.urgency == NotificationUrgency.Critical) ? "release_alert" : 
                            NotificationUtils.guessMessageType(notificationObject.summary)
                        anchors.fill: parent
                        color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
                            Appearance.mix(Appearance.m3colors.m3onSecondary, Appearance.m3colors.m3onSecondaryContainer, 0.1) :
                            Appearance.m3colors.m3onSecondaryContainer
                        font.pixelSize: 27
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    IconImage {
                        visible: notificationObject.image == "" && notificationObject.appIcon != ""
                        anchors.centerIn: parent
                        implicitSize: 33
                        asynchronous: true
                        source: Quickshell.iconPath(notificationObject.appIcon)
                    }
                    Item {
                        anchors.fill: parent
                        visible: notificationObject.image != ""
                        Image {
                            id: notifImage

                            anchors.fill: parent
                            readonly property int size: parent.width

                            source: notificationObject?.image
                            fillMode: Image.PreserveAspectCrop
                            cache: false
                            antialiasing: true
                            asynchronous: true

                            width: size
                            height: size
                            sourceSize.width: size
                            sourceSize.height: size

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: notifImage.size
                                    height: notifImage.size
                                    radius: Appearance.rounding.full
                                }
                            }
                        }
                        IconImage {
                            visible: notificationObject.appIcon != ""
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            implicitSize: 23
                            asynchronous: true
                            source: Quickshell.iconPath(notificationObject.appIcon)
                        }
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
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        Layout.bottomMargin: 10
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

            // Actions
            Flickable {
                id: actionsFlickable
                Layout.fillWidth: true
                Layout.topMargin: -5
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.bottomMargin: 10
                implicitHeight: actionRowLayout.implicitHeight
                contentWidth: actionRowLayout.implicitWidth
                clip: true

                visible: expanded

                RowLayout {
                    id: actionRowLayout

                    Repeater {
                        id: actionRepeater
                        model: notificationObject.actions
                        NotificationActionButton {
                            Layout.fillWidth: true
                            buttonText: modelData.text
                            urgency: notificationObject.urgency
                            onClicked: {
                                Notifications.attemptInvokeAction(notificationObject.id, modelData.identifier);
                            }
                        }
                    }

                    NotificationActionButton {
                        Layout.fillWidth: true
                        buttonText: "Close"
                        urgency: notificationObject.urgency
                        implicitWidth: (notificationObject.actions.length == 0) ? (actionsFlickable.width) : 
                            (contentItem.implicitWidth + leftPadding + rightPadding)
                        onClicked: {
                            Notifications.discardNotification(notificationObject.id);
                        }
                    }
                    
                }
            }
        }
    }
}
