import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

Rectangle {
    id: root

    color: Looks.colors.bg0
    implicitHeight: 48
    
    Rectangle {
        id: border
        anchors {
            left: parent.left
            right: parent.right
            top: Config.options.waffles.bar.bottom ? parent.top : undefined
            bottom: Config.options.waffles.bar.bottom ? undefined : parent.bottom
        }
        color: Looks.colors.bg0Border
        implicitHeight: 1
    }

    BarGroupRow {
        id: bloatRow
        anchors.left: parent.left
    }

    BarGroupRow {
        id: appsRow
        anchors.horizontalCenter: parent.horizontalCenter
    }

    BarGroupRow {
        id: systemRow
        anchors.right: parent.right
        SystemButton {}
        TimeButton {}
    }

    component BarGroupRow: RowLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0
    }
}
