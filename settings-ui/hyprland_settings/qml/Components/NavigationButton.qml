// hyprland-settings/qml/Components/NavigationButton.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import App 1.0
import Components 1.0

Control {
    id: root

    property string text: ""
    property string iconName: ""
    property bool highlighted: false

    signal clicked()

    implicitWidth: 196
    implicitHeight: 56

    contentItem: RowLayout {
        spacing: 12
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 16

        // Контейнер для двух слоев иконок
        Item {
            width: 24
            height: 24
            Layout.alignment: Qt.AlignVCenter

            // Иконка по умолчанию (контурная)
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.iconName
                font.styleName: "Regular"
                color: Theme.text
                opacity: root.highlighted ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Иконка при выделении (заполненная)
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.iconName
                font.styleName: "Filled"
                color: Theme.onSecondaryContainer
                opacity: root.highlighted ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        // Текст (цвет статичный)
        Label {
            text: root.text
            color: Theme.text
            font.pixelSize: 16
            font.weight: Font.Bold
            Layout.alignment: Qt.AlignVCenter
        }
    }

    background: Rectangle { color: "transparent" }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}