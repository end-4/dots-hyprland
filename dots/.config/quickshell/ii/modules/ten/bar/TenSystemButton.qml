import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.ten.looks

Row {
    id: root

    Layout.fillHeight: true
    spacing: 0

    // Network icon
    Rectangle {
        id: networkIcon
        width: 32
        height: 40
        color: "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: 16
            height: 16
            color: TenLooks.colors.subfg
            radius: 8

            // Wifi signal indicator
            Column {
                anchors.centerIn: parent
                spacing: 2
                Rectangle { width: 4; height: 4; color: TenLooks.colors.fg; radius: 2 }
                Rectangle { width: 4; height: 4; color: TenLooks.colors.fg; radius: 2 }
                Rectangle { width: 4; height: 4; color: TenLooks.colors.fg; radius: 2 }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: networkIcon.color = TenLooks.colors.bg1Hover
            onExited: networkIcon.color = "transparent"
        }
    }

    // Volume icon
    Rectangle {
        id: volumeIcon
        width: 32
        height: 40
        color: "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: 16
            height: 16
            color: TenLooks.colors.subfg
            radius: 8

            Rectangle {
                x: 4; y: 6; width: 3; height: 4
                color: TenLooks.colors.fg
            }
            Rectangle {
                x: 7; y: 4; width: 3; height: 8; radius: 1
                color: TenLooks.colors.fg
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: volumeIcon.color = TenLooks.colors.bg1Hover
            onExited: volumeIcon.color = "transparent"
        }
    }

    // Battery icon
    Rectangle {
        id: batteryIcon
        width: 32
        height: 40
        color: "transparent"
        visible: Battery?.available ?? false

        Rectangle {
            anchors.centerIn: parent
            width: 20
            height: 12
            color: TenLooks.colors.subfg
            radius: 2

            Rectangle {
                x: 20; y: 3; width: 2; height: 6
                color: TenLooks.colors.subfg
                radius: 1
            }

            Rectangle {
                x: 2; y: 2; width: 12; height: 8
                color: Battery.isCharging ? TenLooks.colors.accent : TenLooks.colors.fg
                radius: 1
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: batteryIcon.color = TenLooks.colors.bg1Hover
            onExited: batteryIcon.color = "transparent"
        }
    }

    // Show Desktop button (rightmost)
    Rectangle {
        id: showDesktop
        width: 6
        height: 40
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: showDesktop.color = TenLooks.colors.bg1Hover
            onExited: showDesktop.color = "transparent"
        }
    }
}
