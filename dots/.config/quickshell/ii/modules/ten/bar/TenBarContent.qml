import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ten.looks

Rectangle {
    id: root

    // Windows 10 taskbar style - solid color with subtle border
    color: TenLooks.colors.bg0
    implicitHeight: 40 // Windows 10 taskbar height

    Rectangle {
        id: border
        anchors {
            left: parent.left
            right: parent.right
            top: Config.options.ten.bar.bottom ? parent.top : undefined
            bottom: Config.options.ten.bar.bottom ? undefined : parent.bottom
        }
        color: TenLooks.colors.bg0Border
        implicitHeight: 1
    }

    // Left section: Start button and search
    Row {
        id: leftSection
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        TenStartButton {}
        TenSearchButton {}
    }

    // Center section: Pinned apps / Tasks
    TenTasks {
        id: tasksRow
        anchors {
            left: leftSection.right
            right: rightSection.left
            top: parent.top
            bottom: parent.bottom
        }
    }

    // Right section: System tray, clock
    Row {
        id: rightSection
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0

        TenTray {}
        TenSystemButton {}
        TenTimeButton {}
    }
}
