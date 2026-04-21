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

    property bool animateChoiceHighlight: true

    Layout.fillWidth: true
    implicitWidth: contentItem.implicitWidth
    horizontalPadding: 10
    verticalPadding: 11
    buttonSpacing: 8

    color: {
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
    fgColor: colForeground

    background: Rectangle {
        id: backgroundRect
        radius: Looks.radius.medium
        color: root.color
        Behavior on color {
            enabled: root.animateChoiceHighlight
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
                property bool forceZeroHeight: true
                height: forceZeroHeight ? 0 : Math.max(16, root.background.height - 18 * 2)
                Component.onCompleted: {
                    forceZeroHeight = false;
                }

                Behavior on height {
                    enabled: root.animateChoiceHighlight
                    animation: Looks.transition.opacity.createObject(this)
                }
            }
        }
    }
}
