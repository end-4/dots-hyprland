import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Layouts

Item { // Tag suggestion description
    id: root
    property alias text: tagDescriptionText.text

    visible: tagDescriptionText.text.length > 0
    Layout.fillWidth: true
    implicitHeight: tagDescriptionBackground.implicitHeight

    Rectangle {
        id: tagDescriptionBackground
        color: Appearance.colors.colLayer2
        anchors.fill: parent
        radius: Appearance.rounding.verysmall
        implicitHeight: descriptionRow.implicitHeight + 5 * 2

        RowLayout {
            id: descriptionRow
            spacing: 4
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }

            StyledText {
                id: tagDescriptionText
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnLayer2
                wrapMode: Text.Wrap
            }
            KeyboardKey {
                key: "↑"
            }
            KeyboardKey {
                key: "↓"
            }
            StyledText {
                text: qsTr("or")
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            KeyboardKey {
                id: tagDescriptionKey
                key: "Tab"
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}