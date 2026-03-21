import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.ten.looks

Rectangle {
    id: root

    property bool down: false
    property bool hovered: false
    width: searchRow.width + 16
    height: 40

    // Windows 10 search bar styling - pill-shaped
    color: TenLooks.colors.bg1
    radius: 4

    Row {
        id: searchRow
        anchors.centerIn: parent
        spacing: 8

        // Search icon (magnifying glass)
        Rectangle {
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            color: TenLooks.colors.subfg
            radius: 8

            Rectangle {
                x: 4; y: 4; width: 6; height: 6
                color: "transparent"
                border.width: 2
                border.color: TenLooks.colors.subfg
                radius: 3
            }
        }

        Text {
            text: "Type here to search"
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: TenLooks.font.pixelSize.normal
            font.family: TenLooks.font.family.ui
            color: TenLooks.colors.subfg
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            root.hovered = true;
        }
        onExited: {
            root.hovered = false;
        }
        onClicked: {
            GlobalStates.searchOpen = !GlobalStates.searchOpen;
        }
    }
}
