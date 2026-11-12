import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// One stat card: title, big value, optional graph, footer line.
Rectangle {
    id: root
    property string title: ""
    property string icon: ""
    property string value: ""
    property string footerLeft: ""
    property string footerRight: ""
    property var history: []
    property color graphColor: Appearance.colors.colPrimary
    property real barFraction: -1 // >= 0 shows a bar instead of a graph

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        RowLayout {
            spacing: 8
            MaterialSymbol {
                text: root.icon
                iconSize: 20
                color: root.graphColor
            }
            StyledText {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                text: root.value
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer2
            }
        }
        Graph {
            visible: root.barFraction < 0 && root.history.length > 1
            Layout.fillWidth: true
            implicitHeight: 40
            values: root.history
            points: Math.max(root.history.length, 2)
            color: root.graphColor
            fillOpacity: 0.25
        }
        Rectangle {
            visible: root.barFraction >= 0
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Appearance.colors.colSecondaryContainer
            Rectangle {
                height: parent.height
                radius: 3
                width: parent.width * Math.max(0, Math.min(1, root.barFraction))
                color: root.graphColor
            }
        }
        RowLayout {
            visible: root.footerLeft.length > 0 || root.footerRight.length > 0
            StyledText {
                Layout.fillWidth: true
                text: root.footerLeft
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: root.footerRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }
}
