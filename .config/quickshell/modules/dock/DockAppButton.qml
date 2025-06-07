import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

DockButton {
    id: appButton
    required property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: 35
    property real countDotWidth: 10
    property real countDotHeight: 4

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: {
            appListRoot.lastHoveredButton = appButton
            appListRoot.buttonHovered = true
            lastFocused = appToplevel.toplevels.length - 1
        }
        onExited: {
            if (appListRoot.lastHoveredButton === appButton) {
                appListRoot.buttonHovered = false
            }
        }
    }
    onClicked: {
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        appToplevel.toplevels[lastFocused].activate()
    }
    contentItem: Item {
        anchors.centerIn: parent

        IconImage {
            id: iconImage
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            source: Quickshell.iconPath(AppSearch.guessIcon(appToplevel.appId), "image-missing")
            implicitSize: appButton.iconSize
        }

        RowLayout {
            spacing: 3
            anchors {
                top: iconImage.bottom
                topMargin: 2
                horizontalCenter: parent.horizontalCenter
            }
            Repeater {
                model: Math.min(appToplevel.toplevels.length, 3)
                delegate: Rectangle {
                    required property int index
                    radius: Appearance.rounding.full
                    implicitWidth: (appToplevel.toplevels.length <= 3) ? 
                        appButton.countDotWidth : appButton.countDotHeight // Circles when too many
                    implicitHeight: appButton.countDotHeight
                    color: Appearance.m3colors.m3primary
                }
            }
        }
    }
}
