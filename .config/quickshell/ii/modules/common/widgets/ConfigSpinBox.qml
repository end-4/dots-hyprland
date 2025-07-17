import qs.modules.common.widgets
import qs.modules.common
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    property string text: ""
    property alias value: spinBoxWidget.value
    property alias stepSize: spinBoxWidget.stepSize
    property alias from: spinBoxWidget.from
    property alias to: spinBoxWidget.to
    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    StyledText {
        id: labelWidget
        Layout.fillWidth: true
        text: root.text
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colOnSecondaryContainer
    }

    StyledSpinBox {
        id: spinBoxWidget
        Layout.fillWidth: false
        value: root.value
    }
}
