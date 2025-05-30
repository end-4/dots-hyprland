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
    contentItem: IconImage {
        id: iconImage
        source: Quickshell.iconPath(AppSearch.guessIcon(appToplevel.appId), "image-missing")
    }
}
