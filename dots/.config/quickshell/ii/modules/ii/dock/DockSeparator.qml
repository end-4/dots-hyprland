import qs.modules.common
import QtQuick
import QtQuick.Layouts

Rectangle {
    Layout.topMargin: dockRow.padding + Appearance.rounding.normal
    Layout.bottomMargin: dockRow.padding + Appearance.rounding.normal
    Layout.fillHeight: true
    implicitWidth: 1
    color: Appearance.colors.colOutlineVariant
}
