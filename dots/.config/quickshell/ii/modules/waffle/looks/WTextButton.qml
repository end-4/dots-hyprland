pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.waffle.looks

WButton {
    id: root
    implicitHeight: 40
    implicitWidth: contentItem.implicitWidth + 30
    color: "transparent"

    contentItem: Item {
        id: contentItem
        anchors.centerIn: parent
        implicitWidth: buttonText.implicitWidth

        WText {
            id: buttonText
            anchors.centerIn: parent
            color: root.pressed ? Looks.colors.fg : Looks.colors.fg1
            text: root.text
        }
    }
}
