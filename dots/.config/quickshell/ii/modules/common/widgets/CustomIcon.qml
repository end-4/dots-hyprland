import QtQuick
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    
    property bool colorize: false
    property color color
    property string source: ""
    property string iconFolder: Qt.resolvedUrl(Quickshell.shellPath("assets/icons"))  // The folder to check first
    width: 30
    height: 30
    
    readonly property string bundledPath: iconFolder + "/" + root.source

    Image {
        id: bundledProbe
        visible: false
        source: root.source.length > 0 ? root.bundledPath : ""
    }

    IconImage {
        id: iconImage
        anchors.fill: parent
        source: {
            if (root.source.length === 0) return ""
            if (bundledProbe.status === Image.Ready) return root.bundledPath
            return Quickshell.iconPath(root.source)
        }
        implicitSize: root.height
    }

    Loader {
        active: root.colorize
        anchors.fill: iconImage
        sourceComponent: ColorOverlay {
            source: iconImage
            color: root.color
        }
    }
}
