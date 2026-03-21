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
    width: 46
    height: 40

    // Windows 10 Start button styling - hover highlight
    color: {
        if (down) return TenLooks.colors.bg1Active
        if (hovered) return TenLooks.colors.bg1Hover
        return "transparent"
    }

    // Windows logo icon (simplified 4-window icon)
    Rectangle {
        id: windowsLogo
        anchors.centerIn: parent
        width: 20
        height: 20

        // Create Windows-like logo with 4 quadrants
        Rectangle {
            x: 0; y: 0; width: 9; height: 9
            color: down ? TenLooks.colors.accentActive : TenLooks.colors.accent
            radius: 1
        }
        Rectangle {
            x: 11; y: 0; width: 9; height: 9
            color: down ? TenLooks.colors.accentActive : TenLooks.colors.accent
            radius: 1
        }
        Rectangle {
            x: 0; y: 11; width: 9; height: 9
            color: down ? TenLooks.colors.accentActive : TenLooks.colors.accent
            radius: 1
        }
        Rectangle {
            x: 11; y: 11; width: 9; height: 9
            color: down ? TenLooks.colors.accentActive : TenLooks.colors.accent
            radius: 1
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: (event) => {
            root.down = true;
        }
        onReleased: (event) => {
            root.down = false;
        }
        onEntered: {
            root.hovered = true;
        }
        onExited: {
            root.hovered = false;
        }
        onClicked: (event) => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.searchOpen = !GlobalStates.searchOpen;
            }
            if (event.button === Qt.RightButton) {
                // Right-click could open a context menu (like Windows 10 power user menu)
                GlobalStates.searchOpen = !GlobalStates.searchOpen;
            }
        }
    }
}
