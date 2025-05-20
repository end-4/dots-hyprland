import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQml
import Qt.labs.platform
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Button {
    id: root
    property var imageData
    property var rowHeight
    property bool manualDownload: false
    property string previewDownloadPath
    property string downloadPath
    property string nsfwPath
    property string fileName: decodeURIComponent((imageData.file_url).substring((imageData.file_url).lastIndexOf('/') + 1))
    property string filePath: `${root.previewDownloadPath}/${root.fileName}`
    property int maxTagStringLineLength: 50

    property bool showActions: false
    Process {
        id: downloadProcess
        running: false
        command: ["bash", "-c", `[ -f ${root.filePath} ] || curl '${root.imageData.preview_url ?? root.imageData.sample_url}' -o '${root.filePath}'`]
        onExited: (exitCode, exitStatus) => {
            imageObject.source = `${previewDownloadPath}/${root.fileName}`
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
            visible: opacity > 0
            opacity: status === Image.Ready ? 1 : 0

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: imageObject.width
                    height: imageObject.height
                    radius: Appearance.rounding.small
                }
            }

            Behavior on opacity {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
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

            StyledToolTip {
                content: `${StringUtils.wordWrap(root.imageData.tags, root.maxTagStringLineLength)}\n${qsTr("Click for options")}`
            }

            background: Rectangle {
                color: menuButton.down ? ColorUtils.transparentize(ColorUtils.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.6), 0.1) :
                    menuButton.hovered ? ColorUtils.transparentize(ColorUtils.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.8), 0.2) :
                    ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.3)
                radius: Appearance.rounding.full
            }

            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.m3colors.m3onSurface
                text: "more_vert"
            }

            onClicked: {
                root.showActions = !root.showActions
            }
        }

        Loader {
            id: contextMenuLoader
            active: root.showActions
            anchors.top: menuButton.bottom
            anchors.right: parent.right
            anchors.margins: 8

            sourceComponent: Item {
                width: contextMenu.width
                height: contextMenu.height

                Rectangle {
                    id: contextMenu
                    anchors.centerIn: parent
                    opacity: root.showActions ? 1 : 0
                    visible: opacity > 0
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    implicitHeight: contextMenuColumnLayout.implicitHeight + radius * 2
                    implicitWidth: contextMenuColumnLayout.implicitWidth

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        source: contextMenu
                        anchors.fill: contextMenu
                        shadowEnabled: true
                        shadowColor: Appearance.colors.colShadow
                        shadowVerticalOffset: 1
                        shadowBlur: 0.5
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    ColumnLayout {
                        id: contextMenuColumnLayout
                        anchors.centerIn: parent
                        spacing: 0

                        MenuButton {
                            id: openFileLinkButton
                            Layout.fillWidth: true
                            buttonText: qsTr("Open file link")
                            onClicked: {
                                root.showActions = false
                                Hyprland.dispatch("keyword cursor:no_warps true")
                                Qt.openUrlExternally(root.imageData.file_url)
                                Hyprland.dispatch("keyword cursor:no_warps false")
                            }
                        }
                        MenuButton {
                            id: sourceButton
                            visible: root.imageData.source && root.imageData.source.length > 0
                            Layout.fillWidth: true
                            buttonText: StringUtils.format(qsTr("Go to source ({0})"), StringUtils.getDomain(root.imageData.source))
                            enabled: root.imageData.source && root.imageData.source.length > 0
                            onClicked: {
                                root.showActions = false
                                Hyprland.dispatch("keyword cursor:no_warps true")
                                Qt.openUrlExternally(root.imageData.source)
                                Hyprland.dispatch("keyword cursor:no_warps false")
                            }
                        }
                        MenuButton {
                            id: downloadButton
                            Layout.fillWidth: true
                            buttonText: qsTr("Download")
                            onClicked: {
                                root.showActions = false
                                Hyprland.dispatch(`exec curl '${root.imageData.file_url}' -o '${root.imageData.is_nsfw ? root.nsfwPath : root.downloadPath}/${root.fileName}' && notify-send '${qsTr("Download complete")}' '${root.downloadPath}/${root.fileName}'`)
                            }
                        }
                    }
                }
            }
        }
    }
}