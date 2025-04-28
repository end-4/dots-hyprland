import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Button {
    id: root
    property var imageData
    property var rowHeight

    padding: 0

    PointingHandInteraction {}

    background: Rectangle {
        implicitWidth: imageData.width
        implicitHeight: imageData.height
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer2
    }

    contentItem: Image {
        id: imageData
        anchors.fill: parent
        sourceSize.width: imageRow.rowHeight * modelData.aspect_ratio
        sourceSize.height: imageRow.rowHeight
        fillMode: Image.PreserveAspectFit
        source: modelData.preview_url
        width: imageRow.rowHeight * modelData.aspect_ratio
        height: imageRow.rowHeight

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: imageData.width
                height: imageData.height
                radius: Appearance.rounding.small
            }
        }
    }
}