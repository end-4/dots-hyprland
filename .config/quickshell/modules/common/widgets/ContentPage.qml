import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "root:/modules/common/"
import "root:/modules/common/widgets/"

Flickable {
    id: root
    property real baseWidth: 400
    default property alias data: contentColumn.data

    clip: true
    contentHeight: contentColumn.implicitHeight
    implicitWidth: Math.max(contentColumn.implicitWidth, baseWidth)
    ColumnLayout {
        id: contentColumn
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            margins: 10
        }
        spacing: 20
    }
}
