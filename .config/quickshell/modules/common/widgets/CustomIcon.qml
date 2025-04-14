import QtQuick
import Qt.labs.platform
import Quickshell
import Quickshell.Widgets

Item {
    id: root
    
    property string source: ""
    property string iconFolder: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0] + "/quickshell/assets/icons"  // The folder to check first
    width: 30
    height: 30
    
    IconImage {
        id: iconImage
        anchors.fill: parent
        source: {
            if (iconFolder && iconFolder + "/" + root.source) {
                return iconFolder + "/" + root.source
            }
            return root.source
        }
    }
}
