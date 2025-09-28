// hyprland-settings/qml/components/controls/StyledButton.qml
import QtQuick
import QtQuick.Controls
import App 1.0


Button {
    id: root
    implicitHeight: 40
    implicitWidth: contentItem.implicitWidth + 24

    

    contentItem: Text {
        text: root.text
        font.family: Theme.mainFont.family
        font.pixelSize: Theme.mainFont.pixelSize
        font.weight: Font.Bold
        color: root.highlighted ? (Theme.background || "#111") : Theme.primary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: Theme.radius
        color: root.highlighted ? Theme.primary : Theme.surfaceContainerHigh
        border.color: root.highlighted ? "transparent" : Theme.outline
        border.width: 1
    }
}