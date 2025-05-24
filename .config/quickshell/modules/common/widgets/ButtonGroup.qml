import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * A container that supports bouncy children. 
 * https://m3.material.io/components/button-groups/overview
 */
Rectangle {
    id: root
    default property alias content: rowLayout.data
    property real spacing: 5
    property real padding: 5

    property real contentWidth: {
        let total = 0;
        for (let i = 0; i < rowLayout.children.length; ++i) {
            if (rowLayout.children[i].baseWidth !== undefined)
                total += rowLayout.children[i].baseWidth;
        }
        return total + rowLayout.spacing * (rowLayout.children.length - 1);
    }

    topLeftRadius: rowLayout.children.length > 0 ? (rowLayout.children[0].radius + padding) : 
        Appearance?.rounding?.small
    bottomLeftRadius: topLeftRadius
    topRightRadius: {
        console.log(rowLayout.children.length > 0 ? (rowLayout.children[rowLayout.children.length - 1].radius + padding) : 
            Appearance?.rounding?.small)
        return rowLayout.children.length > 0 ? (rowLayout.children[rowLayout.children.length - 1].radius + padding) : 
            Appearance?.rounding?.small
    }
    bottomRightRadius: topRightRadius

    color: "transparent"
    width: root.contentWidth + padding * 2
    implicitHeight: rowLayout.implicitHeight + padding * 2
    
    children: [RowLayout {
        id: rowLayout
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.spacing
        property int clickIndex: -1        
    }]
}
