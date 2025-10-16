import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import "../bar" as Bar

Item { // Full hitbox
    id: root

    implicitHeight: content.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth
    property var dayOfMonth: DateTime.shortDate.split(/[-\/]/)[0]  // What if 🍔murica🦅? good question
    property var monthOfYear: DateTime.shortDate.split(/[-\/]/)[1]

    Item { // Boundaries for date numbers
        id: content
        anchors.centerIn: parent
        implicitWidth: 24
        implicitHeight: 30

        Shape {
            id: diagonalLine
            property real padding: 4
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 1.2
                strokeColor: Appearance.colors.colSubtext
                fillColor: "transparent"
                startX: content.width - diagonalLine.padding
                startY: diagonalLine.padding
                PathLine {
                    x: diagonalLine.padding
                    y: content.height - diagonalLine.padding
                }
            }
        }

        StyledText {
            id: dayText
            anchors {
                top: parent.top
                left: parent.left
            }
            font.pixelSize: 13
            color: Appearance.colors.colOnLayer1
            text: dayOfMonth
        }

        StyledText {
            id: monthText
            anchors {
                bottom: parent.bottom
                right: parent.right
            }
            font.pixelSize: 13
            color: Appearance.colors.colOnLayer1
            text: monthOfYear
        }
    }
}
