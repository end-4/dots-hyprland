import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

StyledText {
    text: "Dialog Title"
    color: Appearance.colors.colOnSurface
    wrapMode: Text.Wrap
    font {
        pixelSize: Appearance.font.pixelSize.title
        family: Appearance.font.family.title
    }
}
