import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * Bottom-left chip of the Intelligence tab: shows the current backend and
 * flips between the API models and local Claude Code when clicked.
 */
RippleButton {
    id: root
    property string symbol: "api"
    property string label: ""
    property string tooltipText: ""

    // Same box as ApiInputBoxIndicator so the API layout stays put
    // (Basic style binds horizontalPadding to padding + 2, so set each side.)
    leftPadding: 4
    rightPadding: 4
    topPadding: 4
    bottomPadding: 4
    implicitHeight: rowLayout.implicitHeight + 4 * 2
    implicitWidth: rowLayout.implicitWidth + 4 * 2
    buttonRadius: Appearance.rounding.verysmall
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.colors.colLayer2Active

    onClicked: ClaudeCode.toggleActive()

    contentItem: RowLayout {
        id: rowLayout

        MaterialSymbol {
            text: root.symbol
            iconSize: Appearance.font.pixelSize.normal
        }
        StyledText {
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.m3colors.m3onSurface
            elide: Text.ElideRight
            text: root.label
            animateChange: true
        }
        MaterialSymbol {
            text: "swap_horiz"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
        }
    }

    StyledToolTip {
        text: root.tooltipText
        extraVisibleCondition: root.tooltipText.length > 0
    }
}
