import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import Qt.labs.platform
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Button {
    id: root
    property var imageData
    property var rowHeight
    property bool manualDownload: false
    property string previewDownloadPath
    property string downloadPath
    property string nsfwPath
    property string fileName: decodeURIComponent((imageData.file_url).substring((imageData.file_url).lastIndexOf('/') + 1))

    Process {
        id: downloadProcess
        running: false
        command: ["bash", "-c", `curl '${imageData.preview_url}' -o '${previewDownloadPath}/${root.fileName}' && echo 'done'`]
        stdout: SplitParser {
            onRead: (data) => {
                console.log("Download output:", data)
                if(data.includes("done")) {
                    imageObject.source = `${previewDownloadPath}/${root.fileName}`
                }
            }
        }
    }

    Component.onCompleted: {
        if (root.manualDownload) {
            downloadProcess.running = true
        }
    }

    padding: 0
    implicitWidth: imageObject.width
    implicitHeight: imageObject.height

    PointingHandInteraction {}

    onClicked: {
        Hyprland.dispatch(`exec xdg-open ${imageData.source}`)
    }

    background: Rectangle {
        implicitWidth: imageObject.width
        implicitHeight: imageObject.height
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2
    }

    contentItem: Image {
        id: imageObject
        anchors.fill: parent
        sourceSize.width: root.rowHeight * modelData.aspect_ratio
        sourceSize.height: root.rowHeight
        fillMode: Image.PreserveAspectFit
        source: modelData.preview_url
        width: root.rowHeight * modelData.aspect_ratio
        height: root.rowHeight

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: imageObject.width
                height: imageObject.height
                radius: Appearance.rounding.small
            }
        }
    }
}