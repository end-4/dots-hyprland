import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property alias materialIcon: icon.text
    property alias text: noticeText.text

    radius: Appearance.rounding.normal
    color: Appearance.colors.colPrimaryContainer
    implicitWidth: mainRowLayout.implicitWidth + mainRowLayout.anchors.margins * 2
    implicitHeight: mainRowLayout.implicitHeight + mainRowLayout.anchors.margins * 2

    RowLayout {
        id: mainRowLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        MaterialSymbol {
            id: icon
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignTop
            text: "info"
            iconSize: Appearance.font.pixelSize.huge
            color: Appearance.colors.colOnPrimaryContainer
        }

        StyledText {
            id: noticeText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: "Notice message"
            color: Appearance.colors.colOnPrimaryContainer
            wrapMode: Text.WordWrap
        }
    }
}
