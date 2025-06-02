import "root:/modules/common"
import QtQuick
import QtQuick.Controls

TextArea {
    renderType: Text.NativeRendering
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.m3colors.m3secondaryContainer
    placeholderTextColor: Appearance.m3colors.m3outline
}
