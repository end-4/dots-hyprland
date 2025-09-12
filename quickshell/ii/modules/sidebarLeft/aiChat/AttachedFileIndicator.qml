pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root

    signal remove()
    property bool canRemove: true
    property string filePath: ""
    property string mimeType: ""
    property real maxHeight: 200
    property real imageWidth: -1
    property real imageHeight: -1
    property real scale: Math.min(root.maxHeight / imageHeight, root.width / imageWidth)
    onFilePathChanged: refresh()
    visible: filePath !== ""

    function refresh() {
        root.mimeType = "";
        root.imageWidth = -1;
        root.imageHeight = -1;
        fileTypeProc.exec(["file", "-b", "--mime-type", filePath]);
    }

    Process {
        id: fileTypeProc
        command: ["file", "-b", "--mime-type", filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                root.mimeType = this.text;
                if (root.mimeType.startsWith("image/"))
                    imageSizeProc.exec(["identify", "-format", "%wx%h", filePath]);
            }
        }
    }

    Process {
        id: imageSizeProc
        command: ["identify", "-format", "%wx%h", filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const dimensions = this.text.split("x");
                root.imageWidth = parseInt(dimensions[0]);
                root.imageHeight = parseInt(dimensions[1]);
            }
        }
    }

    // Styles/widgets
    property real horizontalPadding: 10
    property real verticalPadding: 10
    radius: Appearance.rounding.small - anchors.margins
    color: Appearance.colors.colLayer2
    implicitHeight: visible ? (contentItem.implicitHeight + verticalPadding * 2) : 0

    ColumnLayout {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }

        RowLayout {
            MaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: {
                    if (root.mimeType.startsWith("image/"))
                        return "image";
                    if (root.mimeType.startsWith("audio/"))
                        return "music_note";
                    if (root.mimeType.startsWith("video/"))
                        return "movie";
                    if (root.mimeType === "application/pdf")
                        return "picture_as_pdf";
                    if (root.mimeType.startsWith("text/"))
                        return "description";
                    return "file_present";
                }
                iconSize: Appearance.font.pixelSize.hugeass
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: root.filePath
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.monospace
                wrapMode: Text.Wrap
            }

            RippleButton {
                visible: root.canRemove
                Layout.alignment: Qt.AlignTop
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colLayer2
                implicitHeight: 28
                implicitWidth: 28
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnSurfaceVariant
                }

                onClicked: root.remove()
            }
        }

        Loader {
            id: imagePreviewLoader
            visible: (root.imageWidth != -1) && (root.imageHeight != -1)
            Layout.alignment: Qt.AlignHCenter
            sourceComponent: Item {
                implicitHeight: root.imageHeight * root.scale
                implicitWidth: imagePreview.implicitWidth
                Image {
                    id: imagePreview
                    anchors.fill: parent
                    source: Qt.resolvedUrl(root.filePath)
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
                    asynchronous: true
                    width: root.imageWidth * root.scale
                    height: root.imageHeight * root.scale
                    sourceSize.width: root.imageWidth * root.scale
                    sourceSize.height: root.imageHeight * root.scale

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imagePreview.width
                            height: imagePreview.height
                            radius: Appearance.rounding.normal
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Appearance.colors.colOutlineVariant
                        radius: Appearance.rounding.normal
                    }
                }
            }
        }
    }
}
