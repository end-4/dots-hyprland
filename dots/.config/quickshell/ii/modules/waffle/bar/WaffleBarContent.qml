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
        id: appsRow
        spacing: 4
        anchors.left: undefined
        anchors.horizontalCenter: parent.horizontalCenter

        states: State {
            name: "left"
            when: Config.options.waffles.bar.leftAlignApps
            AnchorChanges {
                target: appsRow
                anchors.left: parent.left
                anchors.horizontalCenter: undefined
            }
        }

        transitions: Transition {
            animations: Looks.transition.anchor.createObject(this)
        }

        StartButton {}
        SearchButton {}
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
