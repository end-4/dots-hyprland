import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

WButton {
    id: root

    Layout.fillWidth: true
    implicitWidth: contentItem.implicitWidth
    horizontalPadding: 10
    verticalPadding: 11
    inset: 0
    buttonSpacing: 8

    property color color: {
        if (root.checked) {
            if (root.down) {
                return root.colBackgroundHover;
            } else if (root.hovered && !root.down) {
                return root.colBackgroundActive;
            } else {
                return root.colBackgroundHover;
            }
        }
        if (root.down) {
            return root.colBackgroundActive;
        } else if (root.hovered && !root.down) {
            return root.colBackgroundHover;
        } else {
            return root.colBackground;
        }
    }

    background: Rectangle {
        id: backgroundRect
        radius: Looks.radius.medium
        color: root.color
        Behavior on color {
            animation: Looks.transition.color.createObject(this)
        }

        WFadeLoader {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            shown: root.checked
            sourceComponent: Rectangle {
                implicitWidth: 3
                implicitHeight: 3
                radius: width / 2
                color: Looks.colors.accent
                Component.onCompleted: {
                    implicitHeight = 16;
                }

                Behavior on implicitHeight {
                    animation: Looks.transition.opacity.createObject(this)
                }
            }
        }
    }
}
