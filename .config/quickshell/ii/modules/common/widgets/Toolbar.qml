import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

/**
 * Material 3 expressive style toolbar.
 * https://m3.material.io/components/toolbars
 */
Item {
    id: root

    property real padding: 8
    property alias colBackground: background.color
    property alias spacing: toolbarLayout.spacing
    default property alias data: toolbarLayout.data
    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight

    StyledRectangularShadow {
        target: background
    }

    Rectangle {
        id: background
        anchors.centerIn: parent
        color: Appearance.m3colors.m3surfaceContainer // Needs to be opaque
        implicitHeight: Math.max(toolbarLayout.implicitHeight + root.padding * 2, 56)
        implicitWidth: toolbarLayout.implicitWidth + root.padding * 2
        radius: Appearance.rounding.full

        RowLayout {
            id: toolbarLayout
            spacing: 4
            anchors {
                fill: parent
                margins: root.padding
            }
        }
    }
}
