import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    ListView { // Scrollable window
        id: listview
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        contentHeight: columnLayout.height

        clip: true
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: listview.width
                height: listview.height
                radius: Appearance.rounding.normal
            }
        }

        add: Transition {
            animations: [
                Appearance.animation.elementMove.numberAnimation.createObject(this, {
                    properties: "opacity,scale",
                    from: 0,
                    to: 1,
                }),
            ]
        }

        addDisplaced: Transition {
            animations: [
                Appearance.animation.elementMove.numberAnimation.createObject(this, {
                    property: "y",
                }),
                Appearance.animation.elementMove.numberAnimation.createObject(this, {
                    properties: "opacity,scale",
                    to: 1,
                }),
            ]
        }
        
        displaced: Transition {
            animations: [
                Appearance.animation.elementMove.numberAnimation.createObject(this, {
                    property: "y",
                }),
            ]
        }
        move: Transition {
            animations: [
                Appearance.animation.elementMove.numberAnimation.createObject(this, {
                    property: "y",
                }),
            ]
        }

        remove: Transition {
            animations: [
                Appearance.animation.elementMove.numberAnimation.createObject(this, {
                    property: "x",
                    to: listview.width,
                }),
                Appearance.animation.elementMove.numberAnimation.createObject(this, {
                    property: "opacity",
                    to: 0,
                })
            ]
        }

        model: ScriptModel {
            values: Notifications.list.slice().reverse()
        }
        delegate: NotificationWidget {
            required property var modelData
            id: notificationWidget
            // anchors.horizontalCenter: parent.horizontalCenter
            anchors.left: parent?.left
            anchors.right: parent?.right
            Layout.fillWidth: true
            notificationObject: modelData
        }
    }

    // Placeholder when list is empty
    Item {
        anchors.fill: listview

        visible: opacity > 0
        opacity: (Notifications.list.length === 0) ? 1 : 0

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
            text: `${Notifications.list.length} notifications`

            opacity: Notifications.list.length > 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
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