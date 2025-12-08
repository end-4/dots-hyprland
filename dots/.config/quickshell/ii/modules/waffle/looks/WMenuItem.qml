pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

MenuItem {
    id: root

    property color colBackground: ColorUtils.transparentize(Looks.colors.bg1)
    property color colBackgroundHover: Looks.colors.bg2Hover
    property color colBackgroundActive: Looks.colors.bg2Active
    property color colBackgroundToggled: Looks.colors.accent
    property color colBackgroundToggledHover: Looks.colors.accentHover
    property color colBackgroundToggledActive: Looks.colors.accentActive
    property color colForeground: Looks.colors.fg
    property color colForegroundToggled: Looks.colors.accentFg
    property color colForegroundDisabled: ColorUtils.transparentize(Looks.colors.subfg, 0.4)
    property color color: {
        if (!root.enabled)
            return colBackground;
        if (root.checked) {
            if (root.down) {
                return root.colBackgroundToggledActive;
            } else if (root.hovered) {
                return root.colBackgroundToggledHover;
            } else {
                return root.colBackgroundToggled;
            }
        }
        if (root.down) {
            return root.colBackgroundActive;
        } else if (root.hovered) {
            return root.colBackgroundHover;
        } else {
            return root.colBackground;
        }
    }
    property color fgColor: {
        if (root.checked)
            return root.colForegroundToggled;
        if (root.enabled)
            return root.colForeground;
        return root.colForegroundDisabled;
    }

    property real inset: 2
    topInset: inset
    bottomInset: inset
    leftInset: inset
    rightInset: inset
    horizontalPadding: 11

    width: ListView.view?.width
    height: visible ? implicitHeight : 0

    background: Rectangle {
        id: backgroundRect
        radius: Looks.radius.medium
        color: root.color
        Behavior on color {
            animation: Looks.transition.color.createObject(this)
        }
    }

    implicitHeight: Math.max(28, contentItem.implicitHeight) + topInset + bottomInset
    implicitWidth: contentItem.implicitWidth + leftInset + rightInset + leftPadding + rightPadding

    contentItem: RowLayout {
        id: contentLayout
        spacing: 12
        FluentIcon {
            id: buttonIcon
            monochrome: true
            implicitSize: 20
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter
            color: root.fgColor
            visible: root.icon.name !== "";
            icon: root.icon.name
        }
        WText {
            id: buttonText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            text: root.text
            horizontalAlignment: Text.AlignLeft
            font.pixelSize: Looks.font.pixelSize.large
            color: root.fgColor
        }
    }
}
