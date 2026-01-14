import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property real padding: 9
    property alias colBackground: background.color
    property alias spacing: toolbarLayout.spacing
    property alias radius: background.radius
    default property alias data: toolbarLayout.data
    
    implicitWidth: background.implicitWidth
    implicitHeight: background.implicitHeight

    Rectangle {
        id: background
        anchors.fill: parent
        implicitHeight: 50
        implicitWidth: toolbarLayout.implicitWidth + root.padding * 2
        radius: Looks.radius.large
        color: Looks.colors.bg0Base

        border.width: 1
        border.color: Looks.colors.bg1Border

        RowLayout {
            id: toolbarLayout
            spacing: 4
            anchors {
                fill: parent
                margins: root.padding
            }
        }
    }
}
