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

    property real padding: 6
    property alias colBackground: background.color
    default property alias data: toolbarLayout.data
    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight

    StyledRectangularShadow {
        target: background
    }

    Rectangle {
        id: background
        anchors.centerIn: parent
        color: Appearance.colors.colLayer2
        implicitHeight: toolbarLayout.implicitHeight + root.padding * 2
        implicitWidth: toolbarLayout.implicitWidth + root.padding * 2
        radius: Appearance.rounding.full

        RowLayout {
            id: toolbarLayout
            anchors {
                fill: parent
                margins: root.padding
            }
        }
    }
}
