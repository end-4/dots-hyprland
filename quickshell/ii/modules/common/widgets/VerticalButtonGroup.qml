import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

/**
 * A container that supports GroupButton children for bounciness.
 * See https://m3.material.io/components/button-groups/overview
 */
Rectangle {
    id: root
    default property alias content: columnLayout.data
    property real spacing: 5
    property real padding: 0
    property int clickIndex: columnLayout.clickIndex

    property real contentHeight: {
        let total = 0;
        for (let i = 0; i < columnLayout.children.length; ++i) {
            const child = columnLayout.children[i];
            total += child.baseHeight ?? child.implicitHeight ?? child.height;
        }
        return total + columnLayout.spacing * (columnLayout.children.length - 1);
    }

    topLeftRadius: columnLayout.children.length > 0 ? (columnLayout.children[0].radius + padding) : 
        Appearance?.rounding?.small
    topRightRadius: topLeftRadius
    bottomLeftRadius: columnLayout.children.length > 0 ? (columnLayout.children[columnLayout.children.length - 1].radius + padding) : 
        Appearance?.rounding?.small
    bottomRightRadius: bottomLeftRadius

    color: "transparent"
    height: root.contentHeight + padding * 2
    implicitWidth: columnLayout.implicitWidth + padding * 2
    implicitHeight: root.contentHeight + padding * 2
    
    children: [ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.spacing
        property int clickIndex: -1
    }]
}
