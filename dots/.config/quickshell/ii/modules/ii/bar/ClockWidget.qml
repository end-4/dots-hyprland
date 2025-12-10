import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose

    Layout.fillHeight: true  
    Layout.fillWidth: true  
    Layout.maximumWidth: Config.options.bar.dynamicSizing ? 180 : -1
    implicitWidth: {  
        const timeWidth = timeText.implicitWidth;  
        const dateWidth = showDate ? dateText.implicitWidth + bulletText.implicitWidth : 0;  
        const spacing = showDate ? rowLayout.spacing * 2 : rowLayout.spacing;  
        return timeWidth + dateWidth + spacing + 16; // 16 for padding  
    }
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {  
            id: timeText  
            font.pixelSize: Appearance.font.pixelSize.small  
            color: Appearance.colors.colOnLayer1  
            text: DateTime.time  
        }  
        
        StyledText {  
            id: bulletText  
            visible: root.showDate  
            font.pixelSize: Appearance.font.pixelSize.small  
            color: Appearance.colors.colOnLayer1  
            text: "•"  
        }  
        
        StyledText {  
            id: dateText  
            visible: root.showDate  
            font.pixelSize: Appearance.font.pixelSize.small  
            color: Appearance.colors.colOnLayer1  
            text: DateTime.longDate  
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        ClockWidgetPopup {
            hoverTarget: mouseArea
        }
    }
}
