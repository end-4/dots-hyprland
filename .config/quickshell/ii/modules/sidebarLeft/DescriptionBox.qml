import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item { // Tag suggestion description
    id: root
    property alias text: tagDescriptionText.text
    property bool showArrows: true
    property bool showTab: true

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
                visible: root.showArrows
                key: "↑"
            }
            KeyboardKey {
                visible: root.showArrows
                key: "↓"
            }
            StyledText {
                visible: root.showArrows && root.showTab
                text: Translation.tr("or")
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
            KeyboardKey {
                id: tagDescriptionKey
                visible: root.showTab
                key: "Tab"
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}