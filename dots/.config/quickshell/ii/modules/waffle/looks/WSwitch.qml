import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.modules.common
import qs.modules.waffle.looks

Switch {
    id: root

    implicitWidth: 40
    implicitHeight: 20
    property real indicatorHeight: 12
    property real indicatorPressedHeight: 14
    property real indicatorPressedWidth: 17
    property color checkedColor: Looks.colors.accent
    property color uncheckedColor: Looks.colors.bg1
    property color borderColor: Looks.colors.controlBgInactive

    readonly property real indicatorPressedWidthDiff: indicatorPressedWidth - indicatorHeight
    
    background: Rectangle {
        width: parent.width
        height: parent.height
        radius: height / 2
        color: root.checked ? root.checkedColor : root.uncheckedColor
        border.width: 1
        border.color: root.checked ? root.checkedColor : root.borderColor

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
        Behavior on border.color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    // Custom thumb styling
    indicator: Rectangle {
        implicitWidth: (root.pressed || root.down) ? root.indicatorPressedWidth : root.indicatorHeight
        implicitHeight: (root.pressed || root.down) ? root.indicatorPressedHeight : root.indicatorHeight
        radius: height / 2
        color: root.checked ? Looks.colors.accentFg : root.borderColor
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: {
            if (root.checked) {
                return 24 - (root.pressed || root.down ? root.indicatorPressedWidthDiff : 0);
            } else {
                return (root.pressed || root.down) ? 3 : (Config.options.waffles.tweaks.switchHandlePositionFix ? 4 : 3);
            }
        }

        Behavior on anchors.leftMargin {
            animation: Looks.transition.enter.createObject(this)
        }
        Behavior on implicitWidth {
            animation: Looks.transition.resize.createObject(this)
        }
        Behavior on implicitHeight {
            animation: Looks.transition.resize.createObject(this)
        }
        Behavior on color {
            animation: Looks.transition.color.createObject(this)
        }
    }
}
