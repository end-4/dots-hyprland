pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    
    onPressed: {
        if (mouse.button === Qt.RightButton || mouse.button === Qt.LeftButton) {
            Crypto.getData();
            Quickshell.execDetached(["notify-send", 
                "Crypto", 
                "Refreshing price..."
                , "-a", "Shell"
            ])
        }
    }

    property string imageUrl: ""
    property string symbol: ""
    property string price: ""
    
    RowLayout {
        id: rowLayout
        anchors.centerIn: parent

        // Show fetched image if available
        Item {
            Layout.alignment: Qt.AlignVCenter
            width: Appearance.font.pixelSize.large
            height: Appearance.font.pixelSize.large
            visible: root.imageUrl !== ""

            Image {
                id: coinImg
                anchors.fill: parent
                source: root.imageUrl
                sourceSize.width: Appearance.font.pixelSize.large
                sourceSize.height: Appearance.font.pixelSize.large
                visible: !Crypto.monochromeIcon
            }
            
            Desaturate {
                anchors.fill: parent
                source: coinImg
                desaturation: 1.0
                visible: Crypto.monochromeIcon
            }
        }

        // Fallback to symbol if image is missing
        StyledText {
            visible: root.imageUrl === ""
            font.pixelSize: Appearance.font.pixelSize.small
            font.bold: true
            color: Appearance.colors.colOnLayer1
            // Use fetched symbol
            text: root.symbol
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: root.price
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
