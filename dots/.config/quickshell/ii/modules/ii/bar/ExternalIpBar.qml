pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool hovered: false
    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight
    
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: !Config.options.bar.tooltips.clickToShow
    
    onPressed: {
        if (mouse.button === Qt.LeftButton) {
            // Copy IP to clipboard
            Quickshell.execDetached(["wl-copy", ExternalIp.ip]);
            Quickshell.execDetached(["notify-send", 
                Translation.tr("External IP"), 
                Translation.tr("IP copied to clipboard: ") + ExternalIp.ip,
                "-a", "Shell"
            ]);
        } else if (mouse.button === Qt.RightButton) {
            // Refresh IP
            ExternalIp.getData();
            Quickshell.execDetached(["notify-send", 
                Translation.tr("External IP"), 
                Translation.tr("Refreshing (manually triggered)"),
                "-a", "Shell"
            ]);
        }
    }
    
    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        
        MaterialSymbol {
            fill: 0
            text: "language"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Layout.alignment: Qt.AlignVCenter
        }
        
        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: ExternalIp.loading ? Translation.tr("...") : (ExternalIp.ip || Translation.tr("--"))
            Layout.alignment: Qt.AlignVCenter
        }
    }
    
    StyledPopup {
        id: ipPopup
        hoverTarget: root
        
        contentItem: StyledPopupContent {
            StyledPopupHeaderRow {
                text: Translation.tr("External IP Address")
            }
            
            StyledPopupValueRow {
                text: Translation.tr("IP Address")
                value: ExternalIp.ip || Translation.tr("Not available")
            }
            
            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer2
                text: Translation.tr("Click to copy • Right-click to refresh")
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
