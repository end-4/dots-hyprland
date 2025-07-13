import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common/"
import "root:/modules/common/widgets/"

Flickable {
    id: root
    property real baseWidth: 550
    property bool forceWidth: false
    property real bottomContentPadding: 100

    default property alias data: contentColumn.data

    clip: true
    contentHeight: contentColumn.implicitHeight + root.bottomContentPadding // Add some padding at the bottom
    implicitWidth: contentColumn.implicitWidth
    
    ColumnLayout {
        id: contentColumn
        width: root.forceWidth ? root.baseWidth : Math.max(root.baseWidth, implicitWidth)
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            margins: 10
        }
        spacing: 20
    }
}
