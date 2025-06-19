import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common/"
import "root:/modules/common/widgets/"

Flickable {
    id: root
    property real baseWidth: 500
    property bool forceWidth: false

    default property alias data: contentColumn.data

    clip: true
    contentHeight: contentColumn.implicitHeight
    implicitWidth: contentColumn.implicitWidth
    
    ColumnLayout {
        id: contentColumn
        width: root.forceWidth ? root.baseWidth : Math.max(root.baseWidth, implicitWidth)
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            margins: 10
        }
        spacing: 20
    }
}
