import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls
import qs.modules.common

ComboBox {
    id: root
    
    Material.theme: Material.System
    Material.accent: Appearance.m3colors.m3primary
    Material.primary: Appearance.m3colors.m3primary
    Material.background: Appearance.m3colors.m3surface
    Material.foreground: Appearance.m3colors.m3onSurface
    Material.containerStyle: Material.Outlined
}
