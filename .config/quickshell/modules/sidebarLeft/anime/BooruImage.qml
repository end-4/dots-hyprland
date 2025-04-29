import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

Button {
    id: root
    property var imageData
    property var rowHeight

    // onImageDataChanged: {
    //     console.log("Image data changed:", imageData)
    // }

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