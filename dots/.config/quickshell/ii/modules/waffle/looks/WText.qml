import QtQuick

Text {
    id: root

    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    color: Looks.colors.fg

    font {
        family: Looks.font.family.ui
        pixelSize: Looks.font.pixelSize.normal
        weight: Looks.font.weight.regular
    }
}
