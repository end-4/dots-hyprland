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

    property alias startRadius: bg.startRadius
    property alias endRadius: bg.endRadius
    property alias topLeftRadius: bg.topLeftRadius
    property alias topRightRadius: bg.topRightRadius
    property alias bottomLeftRadius: bg.bottomLeftRadius
    property alias bottomRightRadius: bg.bottomRightRadius
    property real backgroundWidth: root.vertical ? root.backgroundUndirectionalWidth : root.width
    property real backgroundHeight: root.vertical ? root.height : root.backgroundUndirectionalWidth
    property real fullBackgroundRadius: Math.min(backgroundWidth, backgroundHeight) / 2
    function getBackgroundRadius(atSide) {
        if (root.m3eRadius) {
            if (atSide) return fullBackgroundRadius;
            else return C.Appearance.rounding.unsharpenmore;
        } else {
            return 12;
        }
    }

    property Item background: W.AxisRectangle {
        id: bg
        anchors.centerIn: parent
        contentLayer: W.StyledRectangle.ContentLayer.Group

        width: root.backgroundWidth
        height: root.backgroundHeight

        vertical: root.vertical
        startRadius: root.getBackgroundRadius(root.startSide)
        endRadius: root.getBackgroundRadius(root.endSide)
    }

    property Item contentItem: GridLayout {
        id: layout
        columns: C.Config.options.bar.vertical ? 1 : -1
        anchors.centerIn: parent
        property real spacing: 4
        columnSpacing: spacing
        rowSpacing: spacing
    }

    children: [
        background,
        contentItem
    ]
}
