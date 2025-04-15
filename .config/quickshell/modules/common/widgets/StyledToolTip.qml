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
    }
    StyledText {
        text: content
        id: tooltipText
        color: Appearance.colors.colOnTooltip
    }
}