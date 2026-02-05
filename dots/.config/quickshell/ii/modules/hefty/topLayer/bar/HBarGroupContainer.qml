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

    implicitWidth: vertical ? barUndirectionalWidth : layout.implicitWidth + (padding + margins) * 2
    implicitHeight: vertical ? layout.implicitHeight + (padding + margins) * 2 : barUndirectionalWidth

    W.StyledRectangle {
        id: bg
        anchors.centerIn: parent
        contentLayer: W.StyledRectangle.ContentLayer.Pane

        width: (root.vertical ? root.barUndirectionalWidth : root.width) - root.margins * 2
        height: (root.vertical ? root.height : root.barUndirectionalWidth) - root.margins * 2

        property real fullRadius: Math.min(width, height) / 2
        function getRadius(atSide) {
            if (root.m3eRadius) {
                if (atSide) return fullRadius;
                else return C.Appearance.rounding.unsharpenmore;
            } else {
                return 12;
            }
        }
        property real startRadius: getRadius(root.startSide)
        property real endRadius: getRadius(root.endSide)
        topLeftRadius: startRadius
        topRightRadius: root.vertical ? startRadius : endRadius
        bottomLeftRadius: root.vertical ? endRadius : startRadius
        bottomRightRadius: endRadius
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
