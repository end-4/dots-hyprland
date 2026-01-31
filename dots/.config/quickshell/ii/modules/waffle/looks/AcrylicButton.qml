import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

WButton {
    id: root

    colBackground: Looks.colors.bg1
    colBackgroundHover: Looks.colors.bg1Hover
    colBackgroundActive: Looks.colors.bg1Active
    property color colBackgroundBorder
    property color color
    property alias border: background.border
    property alias shinyColor: background.borderColor

    colBackgroundBorder: ColorUtils.transparentize(color, (root.checked || root.hovered) ? Looks.backgroundTransparency : 0)
    color: {
        if (root.down) {
            return root.colBackgroundActive
        } else if ((root.hovered && !root.down) || root.checked) {
            return root.colBackgroundHover
        } else {
            return root.colBackground
        }
    }

    background: AcrylicRectangle {
        id: background
        shiny: ((root.hovered && !root.down) || root.checked)
        color: root.color
        radius: Looks.radius.medium
        border.width: 1
        border.color: root.colBackgroundBorder

        Behavior on border.color {
            animation: Looks.transition.color.createObject(this)
        }
    }
}
