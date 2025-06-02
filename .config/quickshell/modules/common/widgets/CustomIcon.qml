import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root
    
    property string source: ""
    property string iconFolder: "root:/assets/icons"  // The folder to check first
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
        implicitSize: root.height
    }
}
