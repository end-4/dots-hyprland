// hyprland-settings/qml/components/controls/StyledTextField.qml
import QtQuick
import QtQuick.Controls
import App 1.0

TextField {
    id: root
    implicitHeight: 40
    color: Theme.text
    placeholderTextColor: Theme.subtext

    // ИСПРАВЛЕНИЕ
    font.family: Theme.mainFont.family
    font.pixelSize: Theme.mainFont.pixelSize

    background: Rectangle {
        radius: Theme.radius
        color: Theme.surfaceContainer
        border.color: root.activeFocus ? Theme.primary : Theme.outline
        border.width: root.activeFocus ? 2 : 1
    }
}