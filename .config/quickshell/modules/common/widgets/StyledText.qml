import "root:/modules/common"
import QtQuick
import QtQuick.Layouts

Text {
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferFullHinting
    verticalAlignment: Text.AlignVCenter
    font.family: Appearance.font.family.main
    font.pixelSize: Appearance.font.pixelSize.small
    color: Appearance.m3colors.m3onBackground
}
