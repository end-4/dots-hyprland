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

    property bool showActions: false

    Process {
        id: downloadProcess
        running: false
        command: ["bash", "-c", `curl '${root.imageData.preview_url ?? root.imageData.sample_url}' -o '${root.previewDownloadPath}/${root.fileName}' && echo 'done'`]
        stdout: SplitParser {
            onRead: (data) => {
                // console.log("Download output:", data)
                if(data.includes("done")) {
                    imageObject.source = `${previewDownloadPath}/${root.fileName}`
                }
            }
        }
    }

    Component.onCompleted: {
        if (root.manualDownload) {
            // console.log("Manual download triggered")
            // console.log("Image data:", JSON.stringify(root.imageData))
            // console.log("Download command:", downloadProcess.command.join(" "))
            downloadProcess.running = true
        }
    }

    padding: 0
    implicitWidth: imageObject.width
    implicitHeight: imageObject.height

    // PointingHandInteraction {}

    background: Rectangle {
        implicitWidth: imageObject.width
        implicitHeight: imageObject.height
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2
    }

    contentItem: Item {
        anchors.fill: parent

        Image {
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

        Button {
            id: menuButton
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            implicitHeight: 30
            implicitWidth: 30

            PointingHandInteraction {}

            background: Rectangle {
                color: menuButton.down ? Appearance.transparentize(Appearance.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.6), 0.1) :
                    menuButton.hovered ? Appearance.transparentize(Appearance.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.8), 0.2) :
                    Appearance.transparentize(Appearance.m3colors.m3surface, 0.3)
                radius: Appearance.rounding.full
            }

            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.m3colors.m3onSurface
                text: "more_vert"
            }

            onClicked: {
                root.showActions = !root.showActions
            }
        }

        Rectangle {
            id: contextMenu
            visible: root.showActions
            radius: Appearance.rounding.small
            color: Appearance.m3colors.m3surfaceContainer
            anchors.top: menuButton.bottom
            anchors.right: parent.right
            anchors.margins: 8
            implicitHeight: contextMenuColumnLayout.implicitHeight + radius * 2
            implicitWidth: contextMenuColumnLayout.implicitWidth

            ColumnLayout {
                id: contextMenuColumnLayout
                anchors.centerIn: parent
                spacing: 0

                MenuButton {
                    id: openFileLinkButton
                    Layout.fillWidth: true
                    buttonText: "Open file link"
                    onClicked: {
                        root.showActions = false
                        // Hyprland.dispatch("global quickshell:sidebarLeftClose")
                        Hyprland.dispatch(`exec xdg-open '${root.imageData.file_url}'`)
                    }
                }
                MenuButton {
                    id: sourceButton
                    Layout.fillWidth: true
                    buttonText: "Go to source"
                    enabled: root.imageData.source && root.imageData.source.length > 0
                    onClicked: {
                        root.showActions = false
                        Hyprland.dispatch("global quickshell:sidebarLeftClose")
                        Hyprland.dispatch(`exec xdg-open '${root.imageData.source}'`)
                    }
                }
                MenuButton {
                    id: downloadButton
                    Layout.fillWidth: true
                    buttonText: "Download"
                    onClicked: {
                        root.showActions = false
                        // Hyprland.dispatch("global quickshell:sidebarLeftClose")
                        Hyprland.dispatch(`exec curl '${root.imageData.file_url}' -o '${root.imageData.is_nsfw ? root.nsfwPath : root.downloadPath}/${root.fileName}' && notify-send '${qsTr("Download complete")}' '${root.downloadPath}/${root.fileName}'`)
                    }
                }
            }
        }

    }
}