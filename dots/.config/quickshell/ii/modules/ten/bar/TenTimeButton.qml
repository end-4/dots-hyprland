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
    width: 80
    height: 40

    color: {
        if (down) return TenLooks.colors.bg1Active
        if (hovered) return TenLooks.colors.bg1Hover
        return "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            text: DateTime.time
            font.pixelSize: TenLooks.font.pixelSize.normal
            font.family: TenLooks.font.family.ui
            font.weight: TenLooks.font.weight.regular
            color: TenLooks.colors.fg
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: DateTime.date
            font.pixelSize: TenLooks.font.pixelSize.normal - 1
            font.family: TenLooks.font.family.ui
            font.weight: TenLooks.font.weight.regular
            color: TenLooks.colors.subfg
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onEntered: {
            root.hovered = true;
        }
        onExited: {
            root.hovered = false;
        }
        onClicked: (event) => {
            if (event.button === Qt.RightButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
        }
    }
}
