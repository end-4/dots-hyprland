import qs.modules.common
import QtQuick
import QtQuick.Controls

Label {
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    property bool shouldUseRubik: /^\d+$/.test(root.text)
    property var defaultFont: shouldUseRubik ? "Rubik" : Appearance.font.family.main
    
    font {
        hintingPreference: Font.PreferDefaultHinting
        family: defaultFont
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        variableAxes: shouldUseRubik ? ({}) : Appearance.font.variableAxes.main
    }
    color: Appearance?.m3colors.m3onBackground ?? "black"
    linkColor: Appearance?.m3colors.m3primary
}
