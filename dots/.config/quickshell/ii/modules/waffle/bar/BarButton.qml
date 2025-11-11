import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

Button {
    id: root

    Layout.fillHeight: true
    topInset: 4
    bottomInset: 4

    background: AcrylicRectangle {
        shiny: ((root.hovered && !root.down) || root.checked)
        color: {
            if (root.down) {
                return Looks.colors.bg1Active
            } else if ((root.hovered && !root.down) || root.checked) {
                return Looks.colors.bg1Hover
            } else {
                return ColorUtils.transparentize(Looks.colors.bg1)
            }
        }
    }
}
