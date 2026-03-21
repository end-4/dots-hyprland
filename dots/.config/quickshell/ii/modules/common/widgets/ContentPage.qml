import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

StyledFlickable {
    id: root
    property real baseWidth: 600
    property bool forceWidth: false
    property real bottomContentPadding: 100

    default property alias data: contentColumn.data

    clip: true
    focus: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + root.bottomContentPadding
    implicitWidth: contentColumn.implicitWidth
    interactive: contentHeight > height

    ColumnLayout {
        id: contentColumn
        width: root.forceWidth ? root.baseWidth : Math.max(root.baseWidth, implicitWidth)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 30
    }
}
