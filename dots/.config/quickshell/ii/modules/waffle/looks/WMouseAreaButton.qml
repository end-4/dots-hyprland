import QtQuick
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

MouseArea {
    id: root

    property real radius: Looks.radius.medium
    hoverEnabled: true

    property color colBackground: ColorUtils.transparentize(Looks.colors.bg2)
    property color colBackgroundHover: Looks.colors.bg2Hover
    property color colBackgroundActive: Looks.colors.bg2Active
    property color colBorder: ColorUtils.transparentize(Looks.colors.bg2Border)
    property color colBorderHover: Looks.colors.bg2Border
    
    property color color: {
        if (containsMouse) {
            return pressed ? colBackgroundActive : colBackgroundHover;
        } else {
            return colBackground;
        }
    }

    property color borderColor: {
        if (containsMouse) {
            return colBorderHover;
        } else {
            return colBorder;
        }
    }

    property Item background: Rectangle {
        id: bgRect
        parent: root
        anchors.fill: parent
        color: root.color
        radius: root.radius

        border.color: root.borderColor
        border.width: 1
    }
}