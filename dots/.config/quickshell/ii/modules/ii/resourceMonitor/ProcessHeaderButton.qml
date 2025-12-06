import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// Header button component for process list sorting
MouseArea {
    id: headerBtn
    Layout.fillHeight: true
    
    property string text
    property string sortKey
    property string currentSort
    property bool ascending
    property int horizontalAlignment: Text.AlignLeft

    hoverEnabled: true

    RowLayout {
        anchors.fill: parent
        spacing: 4

        Item {
            Layout.fillWidth: true
            visible: headerBtn.horizontalAlignment === Text.AlignRight || headerBtn.horizontalAlignment === Text.AlignHCenter
        }

        StyledText {
            text: headerBtn.text
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: headerBtn.currentSort === headerBtn.sortKey ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
        }

        MaterialSymbol {
            visible: headerBtn.currentSort === headerBtn.sortKey
            text: headerBtn.ascending ? "arrow_upward" : "arrow_downward"
            iconSize: 14
            color: Appearance.m3colors.m3primary
        }

        Item {
            Layout.fillWidth: true
            visible: headerBtn.horizontalAlignment === Text.AlignLeft || headerBtn.horizontalAlignment === Text.AlignHCenter
        }
    }
}
