import QtQuick
import QtQuick.Controls
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

WButton {
    id: root

    colBackground: Looks.colors.bg2
    colBackgroundHover: Looks.colors.bg2Hover
    colBackgroundActive: Looks.colors.bg2Active
    border.color: Looks.colors.bg2Border
    border.width: root.pressed ? 2 : 1

    
}
