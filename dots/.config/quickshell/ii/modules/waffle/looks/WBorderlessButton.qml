import QtQuick
import QtQuick.Controls
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

Button {
    id: root

    implicitHeight: 36

    property color colBackground: ColorUtils.transparentize(Looks.colors.bg1)
    property color colBackgroundHover: Looks.colors.bg1Hover
    property color colBackgroundActive: Looks.colors.bg1Active
    property color color
    property color colForeground: Looks.colors.fg
    color: {
        if (!root.enabled) return colBackground;
        if (root.down) {
            return root.colBackgroundActive
        } else if ((root.hovered && !root.down) || root.checked) {
            return root.colBackgroundHover
        } else {
            return root.colBackground
        }
    }
    property alias radius: background.radius

    background: Rectangle {
        id: background
        radius: Looks.radius.medium
        color: root.color
    }
}
