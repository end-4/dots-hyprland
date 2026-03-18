import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

StyledText {
    Layout.fillWidth: true
    font {
        family: Appearance.font.family.expressive
        pixelSize: 20
        weight: 350
        // Set empty to prevent conflicts, not meaningless
        styleName: ""
        variableAxes: ({})
    }
    style: Text.Raised
    styleColor: Appearance.colors.colShadow
    animateChange: Config.options.background.widgets.clock.digital.animateChange
}