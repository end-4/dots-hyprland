import qs.modules.common
import QtQuick
import QtQuick.Controls

/**
 * Does not include visual layout, but includes the easily neglected colors.
 */
TextInput {
    color: Appearance.colors.colOnLayer1
    renderType: Text.NativeRendering
    selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer
    font {
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
}
