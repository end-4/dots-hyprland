import "root:/"
import "root:/modules/common"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    Layout.topMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
    Layout.bottomMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
    Layout.fillHeight: true
    implicitWidth: 1
    color: Appearance.m3colors.m3outlineVariant
}
