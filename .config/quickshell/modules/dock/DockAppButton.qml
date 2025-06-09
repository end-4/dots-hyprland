import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
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
    property bool appIsActive: !appToplevel.toplevels ? false : appToplevel.toplevels.find(t => (t.activated == true)) !== undefined
    property DesktopEntry entry: DesktopEntries.byId(modelData.appId)

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
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
        onClicked: {
            if (mouse.button === Qt.MiddleButton ) {
                appButton.entry.execute();
                return;
            }
            if (modelData.isPinnedApp && !modelData.isRunning) {
                appButton.entry.execute();
                return;
            }
            lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
            appToplevel.toplevels[lastFocused].activate()
        }
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
                model: ScriptModel {
                    values: {
                        return appToplevel.toplevels ?? []
                    }
                }
                delegate: Rectangle {
                    required property int index
                    radius: Appearance.rounding.full
                    implicitWidth: !appToplevel.toplevels ? 0 : (appToplevel.toplevels.length <= 3) ? 
                        appButton.countDotWidth : appButton.countDotHeight // Circles when too many
                    implicitHeight: appButton.countDotHeight
                    color: appIsActive ? Appearance.m3colors.m3primary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
                }
            }
        }
    }
}
