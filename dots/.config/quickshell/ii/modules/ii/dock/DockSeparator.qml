import qs.modules.common
import QtQuick
import QtQuick.Layouts

Rectangle {
    property real padding: 5

    Layout.topMargin: Appearance.sizes.elevationMargin + padding + Appearance.rounding.normal
    Layout.bottomMargin: Appearance.sizes.hyprlandGapsOut + padding + Appearance.rounding.normal
    Layout.fillHeight: true
    implicitWidth: 1
    color: Appearance.colors.colOutlineVariant
}
