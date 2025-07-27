import qs.singletons
import QtQuick
import QtQuick.Layouts

Text {
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    font {
        hintingPreference: Font.PreferFullHinting
        family: Appearance?.font.family.main ?? "sans-serif"
        pixelSize: Appearance?.font.pixelSize.small ?? 15
    }
    color: Appearance?.colors.on_background ?? "black"
    linkColor: Appearance?.colors.primary ?? "blue"
}
