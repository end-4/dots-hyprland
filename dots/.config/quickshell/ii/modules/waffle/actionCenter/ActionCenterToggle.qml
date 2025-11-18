import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// It should be perfectly fine to use just a Column here, but somehow
// using ColumnLayout prevents weird opening anim stutter
ColumnLayout { 
    id: root

    property alias name: toggleNameText.text

    Rectangle {
        Layout.fillWidth: true
        implicitWidth: 96
        implicitHeight: 48
        color: "transparent"
        border.width: 1
        border.color: Looks.colors.bg0Border // ???
        radius: Looks.radius.medium
    }

    Item {
        implicitHeight: 36
        Layout.fillWidth: true
        WText {
            id: toggleNameText
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
            }
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: "Toggle"
        }
    }
}
