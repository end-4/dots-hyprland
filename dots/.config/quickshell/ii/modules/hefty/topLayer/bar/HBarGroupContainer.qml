import QtQuick
import QtQuick.Layouts
import qs.modules.common as C
import qs.modules.common.widgets as W

Item {
    id: root

    property bool startSide: false
    property bool endSide: false

    property alias color: bg.color
    property real margins: 4
    property real padding: 4
    default property alias data: layout.data

    readonly property bool vertical: C.Config.options.bar.vertical
    readonly property bool m3eRadius: C.Config.options.hefty.bar.m3ExpressiveGrouping
    readonly property real barUndirectionalWidth: C.Config.options.bar.vertical ? C.Appearance.sizes.baseVerticalBarWidth : C.Appearance.sizes.baseBarHeight
    readonly property real backgroundUndirectionalWidth: barUndirectionalWidth - margins * 2

    implicitWidth: vertical ? barUndirectionalWidth : layout.implicitWidth + padding * 2
    implicitHeight: vertical ? layout.implicitHeight + padding * 2 : barUndirectionalWidth

    W.AxisRectangle {
        id: bg
        anchors.centerIn: parent
        contentLayer: W.StyledRectangle.ContentLayer.Pane

        width: root.vertical ? root.backgroundUndirectionalWidth : root.width
        height: root.vertical ? root.height : root.backgroundUndirectionalWidth

        property real fullRadius: Math.min(width, height) / 2
        function getRadius(atSide) {
            if (root.m3eRadius) {
                if (atSide) return fullRadius;
                else return C.Appearance.rounding.unsharpenmore;
            } else {
                return 12;
            }
        }
        vertical: root.vertical
        startRadius: getRadius(root.startSide)
        endRadius: getRadius(root.endSide)
    }

    GridLayout {
        id: layout
        columns: C.Config.options.bar.vertical ? 1 : -1
        anchors.centerIn: parent
        property real spacing: 4
        columnSpacing: spacing
        rowSpacing: spacing
    }
}
