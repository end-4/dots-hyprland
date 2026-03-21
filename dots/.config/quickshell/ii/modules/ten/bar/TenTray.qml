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

    // Notification area / system tray icons
    Rectangle {
        id: trayArea
        width: 60
        height: 40
        color: "transparent"

        // Small colored squares representing tray icons (Windows 10 style)
        Row {
            anchors.centerIn: parent
            spacing: 4

            Rectangle {
                width: 6
                height: 6
                color: TenLooks.colors.accent
                radius: 1
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: 6
                height: 6
                color: TenLooks.colors.fg
                radius: 1
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: 6
                height: 6
                color: TenLooks.colors.subfg
                radius: 1
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: trayArea.color = TenLooks.colors.bg1Hover
            onExited: trayArea.color = "transparent"
        }
    }

    // Up arrow (show hidden icons) - Windows 10 style
    Rectangle {
        id: upArrow
        width: 20
        height: 40
        color: "transparent"

        // Simple up chevron using two lines
        Rectangle {
            anchors.centerIn: parent
            width: 10
            height: 6

            // Up caret shape
            Rectangle {
                x: 2; y: 4
                width: 6; height: 2
                color: TenLooks.colors.subfg
                rotation: 45
            }
            Rectangle {
                x: 4; y: 1
                width: 6; height: 2
                color: TenLooks.colors.subfg
                rotation: -45
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: upArrow.color = TenLooks.colors.bg1Hover
            onExited: upArrow.color = "transparent"
        }
    }
}
