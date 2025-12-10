import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.bar
import Quickshell

Button {
    id: reusableCloseButton
    implicitHeight: 30
    implicitWidth: 30
    property alias radius: closeButtonBg.radius

    Rectangle {
        z: 0
        color: "transparent"
        anchors.fill: closeButtonBg
        anchors.margins: -1
        opacity: closeButtonBg.opacity
        border.width: 1
        radius: closeButtonBg.radius + 1
        border.color: Looks.colors.bg2Border
    }

    background: Rectangle {
        id: closeButtonBg
        z: 1
        opacity: reusableCloseButton.hovered ? 1 : 0
        color: reusableCloseButton.pressed ? Looks.colors.dangerActive : Looks.colors.danger
        Behavior on opacity {
            animation: Looks.transition.opacity.createObject(this)
        }
        Behavior on color {
            animation: Looks.transition.color.createObject(this)
        }
    }
    
    contentItem: FluentIcon {
        z: 2
        anchors.centerIn: parent
        icon: "dismiss"
        implicitSize: 10
    }
}
