pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

Rectangle {
    id: regionRect
    required property color colBackground
    required property color colForeground
    property bool showIcon: false
    property bool targeted: false
    property color borderColor
    property color fillColor: "transparent"
    property string text: ""
    property real textPadding: 10
    z: 2
    color: fillColor
    border.color: borderColor
    border.width: targeted ? 3 : 1
    radius: 4

    Rectangle {
        id: regionLabelBackground
        property real verticalPadding: 5
        property real horizontalPadding: 10
        radius: 10
        color: regionRect.colBackground
        border.width: 1
        border.color: Appearance.m3colors.m3outlineVariant
        anchors {
            top: parent.top
            left: parent.left
            topMargin: regionRect.textPadding
            leftMargin: regionRect.textPadding
        }
        implicitWidth: regionInfoRow.implicitWidth + horizontalPadding * 2
        implicitHeight: regionInfoRow.implicitHeight + verticalPadding * 2
        Row {
            id: regionInfoRow
            anchors.centerIn: parent
            spacing: 4

            Loader {
                id: regionIconLoader
                active: regionRect.showIcon
                visible: active
                sourceComponent: IconImage {
                    implicitSize: Appearance.font.pixelSize.larger
                    source: Quickshell.iconPath(AppSearch.guessIcon(regionRect.text), "image-missing")
                }
            }

            StyledText {
                id: regionText
                text: regionRect.text
                color: regionRect.colForeground
            }
        }
    }
}