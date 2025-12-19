import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.normal
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        StyledText {
            text: Translation.tr("Settings")
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
        }
        
        StyledText {
            text: Translation.tr("Configure your digital wellbeing preferences here.")
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer1
            opacity: 0.7
            wrapMode: Text.WordWrap
        }
        
        Item { Layout.fillHeight: true }
    }
}
