import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

// Small icon + text chip for the controls row
RippleButton {
    id: chip
    property string symbol
    property string label
    property string tooltipText
    leftPadding: 4
    rightPadding: 4
    topPadding: 4
    bottomPadding: 4
    implicitHeight: chipRow.implicitHeight + 8
    implicitWidth: chipRow.implicitWidth + 8
    buttonRadius: Appearance.rounding.verysmall
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.colors.colLayer2Active
    contentItem: RowLayout {
        id: chipRow
        MaterialSymbol {
            text: chip.symbol
            iconSize: Appearance.font.pixelSize.normal
        }
        StyledText {
            text: chip.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.m3colors.m3onSurface
        }
    }
    StyledToolTip {
        text: chip.tooltipText
        extraVisibleCondition: chip.tooltipText.length > 0
    }
}
