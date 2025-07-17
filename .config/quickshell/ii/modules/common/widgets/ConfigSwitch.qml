import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
    id: root
    Layout.fillWidth: true
    implicitHeight: contentItem.implicitHeight + 8 * 2
    onClicked: checked = !checked

    contentItem: RowLayout {
        spacing: 10
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnSecondaryContainer
        }
        StyledSwitch {
            id: switchWidget
            down: root.down
            scale: 0.6
            Layout.fillWidth: false
            checked: root.checked
            onClicked: root.clicked()
        }
    }
}

