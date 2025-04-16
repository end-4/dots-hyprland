import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    required property var taskList;

    Flickable {
        anchors.fill: parent
        contentHeight: column.height
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            Repeater {
                model: taskList
                delegate: Rectangle {
                    Layout.fillWidth: true
                    width: parent.width
                    height: 40
                    color: Appearance.colors.colLayer2
                    radius: Appearance.rounding.small
                    Text {
                        text: modelData.content
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                    }
                }
            }
        }
    }
}