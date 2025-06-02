import "root:/modules/common"
import QtQuick
import QtQuick.Layouts

Text {
    renderType: Text.NativeRendering
    font.hintingPreference: Font.PreferFullHinting
    verticalAlignment: Text.AlignVCenter
    font.family: Appearance?.font.family.main ?? "sans-serif"
    font.pixelSize: Appearance?.font.pixelSize.small ?? 15
    color: Appearance?.m3colors.m3onBackground ?? "black"
}
