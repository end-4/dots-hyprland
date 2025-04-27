import "root:/modules/common"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "./notification_utils.js" as NotificationUtils

Item {
    id: root
    property var notificationObject
    property bool popup: false
    property bool expanded: false
    property bool enableAnimation: true
    property int notificationListSpacing: 5
    property bool ready: false
    property int defaultTimeoutValue: 5000

    Layout.fillWidth: true
    clip: !popup

    implicitHeight: ready ? notificationColumnLayout.implicitHeight + notificationListSpacing : 0
    Behavior on implicitHeight {
        enabled: enableAnimation
        NumberAnimation {
            duration: Appearance.animation.elementDecelFast.duration
            easing.type: Appearance.animation.elementDecel.type
        }
    }

    Component.onCompleted: {
        root.ready = true
        if (popup) timeoutTimer.start()
    }

    Timer {
        id: timeoutTimer
        interval: notificationObject.expireTimeout ?? root.defaultTimeoutValue
        repeat: false
        onTriggered: {
            Notifications.timeoutNotification(notificationObject.id);
        }
    }

    function destroyWithAnimation(delay = 0) {
        destroyTimer0.interval = delay
        destroyTimer0.start()
    }

    function toggleExpanded() {
        root.enableAnimation = true
        notificationRowWrapper.anchors.bottom = undefined
        root.expanded = !root.expanded
    }

    Timer {
        id: destroyTimer0
        interval: 0
        repeat: false
        onTriggered: {
            notificationRowWrapper.anchors.left = undefined
            notificationRowWrapper.anchors.right = undefined
            notificationRowWrapper.anchors.fill = undefined
            notificationBackground.anchors.left = undefined
            notificationBackground.anchors.right = undefined
            notificationBackground.anchors.fill = undefined
            notificationRowWrapper.x = width + 5 * 2 // Account for shadow
            notificationBackground.x = width + 5 * 2 // Account for shadow
            destroyTimer1.start()
        }
    }

    Timer {
        id: destroyTimer1
        interval: Appearance.animation.elementDecelFast.duration
        repeat: false
        onTriggered: {
            notificationRowWrapper.anchors.top = undefined
            notificationRowWrapper.anchors.bottom = root.bottom
            implicitHeight = 0
            destroyTimer2.start()
        }
    }

    Timer {
        id: destroyTimer2
        interval: Appearance.animation.elementDecelFast.duration
        repeat: false
        onTriggered: {
            root.destroy()
        }
    }

    MouseArea {
        // Middle click to close
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button == Qt.MiddleButton) 
                Notifications.discardNotification(notificationObject.id);
            else if (mouse.button == Qt.RightButton) 
                root.toggleExpanded()
        }

        // Flick right to dismiss/discard
        property real startX: 0
        property real dragStartThreshold: 10
        property real dragConfirmThreshold: 70
        property bool dragStarted: false

        onPressed: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                startX = mouse.x
            }
        }
        onPressAndHold: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Hyprland.dispatch(`exec wl-copy '${notificationObject.body}'`)
                notificationSummaryText.text = `${notificationObject.summary} (copied)`
            }
        }
        onDragStartedChanged: () => {
            // Prevent drag focus being shifted to parent flickable
            if (root.parent.parent.parent.interactive !== undefined) root.parent.parent.parent.interactive = !dragStarted
            root.enableAnimation = !dragStarted
        }
        onReleased: (mouse) => {
            dragStarted = false
            if (mouse.button === Qt.LeftButton) {
                if (notificationRowWrapper.x > dragConfirmThreshold) {
                    Notifications.discardNotification(notificationObject.id);
                } else {
                    // Animate back if not far enough
                    notificationRowWrapper.x = 0
                    notificationBackground.x = 0
                }
            }
        }
        onPositionChanged: (mouse) => {
            if (mouse.buttons & Qt.LeftButton) {
                let dx = mouse.x - startX
                if (dragStarted || dx > dragStartThreshold) {
                    dragStarted = true
                    notificationRowWrapper.anchors.left = undefined
                    notificationRowWrapper.anchors.right = undefined
                    notificationRowWrapper.anchors.fill = undefined
                    notificationBackground.anchors.left = undefined
                    notificationBackground.anchors.right = undefined
                    notificationBackground.anchors.fill = undefined
                    notificationRowWrapper.x = Math.max(0, dx)
                    notificationBackground.x = Math.max(0, dx)
                }
            }
        }
    }

    // Background
    Item {
        id: notificationBackgroundWrapper

        // anchors.fill: parent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // anchors.top: parent.top
        anchors.topMargin: notificationListSpacing
        implicitHeight: notificationColumnLayout.implicitHeight + notificationListSpacing

        Rectangle {
            id: notificationBackground
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            // anchors.top: parent.top
            height: notificationColumnLayout.implicitHeight

            color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
                Appearance.mix(Appearance.m3colors.m3secondaryContainer, Appearance.colors.colLayer2, 0.35) : Appearance.colors.colLayer2
            radius: Appearance.rounding.normal

            Behavior on x {
                enabled: enableAnimation
                NumberAnimation {
                    duration: Appearance.animation.elementDecelFast.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }
            Behavior on height {
                enabled: enableAnimation
                NumberAnimation {
                    duration: Appearance.animation.elementDecelFast.duration
                    easing.type: Appearance.animation.elementDecel.type
                }
            }
        }

        DropShadow {
            visible: popup
            id: notificationShadow
            anchors.fill: notificationBackground
            source: notificationBackground
            radius: 5
            samples: radius * 2 + 1
            color: Appearance.colors.colShadow
            verticalOffset: 2
            horizontalOffset: 0
        }
    }


    Item {
        id: notificationRowWrapper
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        // anchors.top: parent.top
        implicitHeight: notificationColumnLayout.implicitHeight + notificationListSpacing

        Behavior on x {
            enabled: enableAnimation
            NumberAnimation {
                duration: Appearance.animation.elementDecelFast.duration
                easing.type: Appearance.animation.elementDecel.type
            }
        }

        ColumnLayout {
            id: notificationColumnLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0
            Item {
                Layout.fillWidth: true
                implicitHeight: notificationRowLayout.implicitHeight
                Behavior on implicitHeight {
                    enabled: enableAnimation
                    NumberAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }

                RowLayout {
                    id: notificationRowLayout
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right

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
                            text: {
                                const defaultIcon = NotificationUtils.findSuitableMaterialSymbol("")
                                const guessedIcon = NotificationUtils.findSuitableMaterialSymbol(notificationObject.summary)
                                return (notificationObject.urgency == NotificationUrgency.Critical && guessedIcon === defaultIcon) ?
                                    "release_alert" : guessedIcon
                            }
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
                                id: notificationSummaryText
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignBottom
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer2
                                text: notificationObject.summary
                                wrapMode: expanded ? Text.Wrap : Text.NoWrap
                                elide: Text.ElideRight
                            }

                            CircularProgress {
                                id: notificationProgress
                                visible: popup
                                Layout.alignment: Qt.AlignVCenter
                                lineWidth: 2
                                value: popup ? 1 : 0
                                size: 20
                                animationDuration: notificationObject.expireTimeout ?? root.defaultTimeoutValue
                                easingType: Easing.Linear

                                Component.onCompleted: {
                                    value = 0
                                }
                            }

                            StyledText { // Time
                                id: notificationTimeText
                                Layout.fillWidth: false
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 3
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
                                Layout.alignment: Qt.AlignTop
                                id: expandButton
                                implicitWidth: 22
                                implicitHeight: 22

                                PointingHandInteraction{}
                                onClicked: {
                                    root.toggleExpanded()
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
                                    text: "keyboard_arrow_down"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer2
                                    rotation: expanded ? 180 : 0
                                    Behavior on rotation {
                                        NumberAnimation {
                                            duration: Appearance.animation.elementDecel.duration
                                            easing.type: Appearance.animation.elementDecel.type
                                        }
                                    }
                                }

                            }
                        }

                        StyledText { // Notification body
                            id: notificationBodyText
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
                            textFormat: expanded ? Text.RichText : Text.StyledText
                            text: expanded 
                                ? `<style>img{max-width:${notificationBodyText.width}px;}</style>` + 
                                  `${notificationObject.body.replace(/\n/g, "<br/>")}` 
                                : notificationObject.body.replace(/<img/g, "\n <img").split("\n")[0]
                            onLinkActivated: {
                                Qt.openUrlExternally(link)
                                Hyprland.dispatch("global quickshell:sidebarRightClose")
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.NoButton // Only for hover
                                hoverEnabled: true
                                cursorShape: notificationBodyText.hoveredLink !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }
                    }
                }
            }

            // Actions
            Flickable {
                id: actionsFlickable
                Layout.fillWidth: true
                // Layout.topMargin: -5
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                Layout.bottomMargin: expanded ? 10 : 0
                implicitHeight: expanded ? actionRowLayout.implicitHeight : 0
                height: expanded ? actionRowLayout.implicitHeight : 0
                contentWidth: actionRowLayout.implicitWidth

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: actionsFlickable.width
                        height: actionsFlickable.height
                        radius: Appearance.rounding.small
                    }
                }

                opacity: expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementDecel.duration
                        easing.type: Appearance.animation.elementDecel.type
                    }
                }

                RowLayout {
                    id: actionRowLayout
                    Layout.alignment: Qt.AlignBottom

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
                        urgency: notificationObject.urgency
                        implicitWidth: (notificationObject.actions.length == 0) ? (actionsFlickable.width / 2) : 
                            (contentItem.implicitWidth + leftPadding + rightPadding)

                        onClicked: {
                            Hyprland.dispatch(`exec wl-copy '${notificationObject.body}'`)
                            copyIcon.text = "inventory"
                            copyIconTimer.stop()
                            copyIconTimer.start()
                        }

                        Timer {
                            id: copyIconTimer
                            interval: 1500
                            repeat: false
                            onTriggered: {
                                copyIcon.text = "content_copy"
                            }
                        }

                        contentItem: MaterialSymbol {
                            id: copyIcon
                            font.pixelSize: Appearance.font.pixelSize.large
                            horizontalAlignment: Text.AlignHCenter
                            color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
                                Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                            text: "content_copy"
                        }
                    }

                    NotificationActionButton {
                        Layout.fillWidth: true
                        buttonText: qsTr("Close")
                        urgency: notificationObject.urgency
                        implicitWidth: (notificationObject.actions.length == 0) ? (actionsFlickable.width / 2) : 
                            (contentItem.implicitWidth + leftPadding + rightPadding)

                        onClicked: {
                            Notifications.discardNotification(notificationObject.id);
                        }

                        contentItem: MaterialSymbol {
                            font.pixelSize: Appearance.font.pixelSize.large
                            horizontalAlignment: Text.AlignHCenter
                            color: (notificationObject.urgency == NotificationUrgency.Critical) ? 
                                Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                            text: "close"
                        }
                    }
                    
                }
            }
        }
    }
}
