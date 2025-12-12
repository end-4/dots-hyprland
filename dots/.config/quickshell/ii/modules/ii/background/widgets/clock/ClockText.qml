import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

StyledText {
    Layout.fillWidth: true
    horizontalAlignment: root.textHorizontalAlignment
    font {
        family: Appearance.font.family.expressive
        pixelSize: 20
        weight: 350
        variableAxes: ({})
        styleName: ""
    }
    color: root.colText
    style: Text.Raised
    styleColor: Appearance.colors.colShadow
    animateChange: Config.options.background.widgets.clock.digital.animateChange
}