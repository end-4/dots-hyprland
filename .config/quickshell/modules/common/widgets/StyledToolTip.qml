import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolTip {
    property string content
    parent: parent
    visible: parent.hovered
    padding: 7
    background: Rectangle {
        color: Appearance.colors.colTooltip
        radius: Appearance.rounding.small
        width: tooltipText.width + 2 * padding
    }
    StyledText {
        id: tooltipText
        text: content
        color: Appearance.colors.colOnTooltip
        wrapMode: Text.WordWrap
    }
}