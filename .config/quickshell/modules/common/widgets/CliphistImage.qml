import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
import Qt5Compat.GraphicalEffects
import Qt.labs.platform
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

Rectangle {
    id: root
    property string entry
    property real maxWidth
    property real maxHeight

    property string imageDecodePath: Directories.cliphistDecode
    property string imageDecodeFileName: `${entryNumber}`
    property string imageDecodeFilePath: `${imageDecodePath}/${imageDecodeFileName}`
    property string source

    property int entryNumber: {
        if (!root.entry) return 0
        const match = root.entry.match(/^(\d+)\t/)
        return match ? parseInt(match[1]) : 0
    }
    property int imageWidth: {
        if (!root.entry) return 0
        const match = root.entry.match(/(\d+)x(\d+)/)
        return match ? parseInt(match[1]) : 0
    }
    property int imageHeight: {
        if (!root.entry) return 0
        const match = root.entry.match(/(\d+)x(\d+)/)
        return match ? parseInt(match[2]) : 0
    }
    property real scale: {
        return Math.min(
            root.maxWidth / imageWidth,
            root.maxHeight / imageHeight,
            1
        )
    }

    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small
    implicitHeight: imageHeight * scale
    implicitWidth: imageWidth * scale

    Component.onCompleted: {
        decodeImageProcess.running = true
    }

    Process {
        id: decodeImageProcess
        command: ["bash", "-c", 
            `[ -f ${imageDecodeFilePath} ] || echo '${StringUtils.shellSingleQuoteEscape(root.entry)}' | cliphist decode > '${imageDecodeFilePath}'`
        ]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.source = imageDecodeFilePath
            } else {
                console.error("[CliphistImage] Failed to decode image for entry:", root.entry)
                root.source = ""
            }
        }
    }

    Component.onDestruction: {
        Hyprland.dispatch(`exec bash -c "[ -f '${imageDecodeFilePath}' ] && rm -f '${imageDecodeFilePath}'"`)
    }

    Image {
        id: image
        anchors.fill: parent

        source: Qt.resolvedUrl(root.source)
        fillMode: Image.PreserveAspectFit
        antialiasing: true
        asynchronous: true

        width: root.imageWidth * root.scale
        height: root.imageHeight * root.scale
        sourceSize.width: width
        sourceSize.height: height

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: image.width
                height: image.height
                radius: root.radius
            }
        }
    }
}

