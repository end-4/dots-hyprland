import qs
import qs.services
import qs.modules.common
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: taskViewScope

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.screen)
            screen: modelData

            visible: GlobalStates.taskViewOpen

            WlrLayershell.namespace: "quickshell:taskview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1 // Cover everything
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Close when clicking empty space
            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.taskViewOpen = false
            }

            // Wallpaper Background to hide actual windows
            property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
            property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath

            // Solid background fallback
            Rectangle {
                anchors.fill: parent
                color: Appearance.colors.colLayer1 // Use theme background color
                z: -2
            }

            Image {
                id: bgWallpaper
                anchors.fill: parent
                source: root.wallpaperPath
                fillMode: Image.PreserveAspectCrop
                visible: false // Hidden, used as source for blur
            }

            GaussianBlur {
                anchors.fill: bgWallpaper
                source: bgWallpaper
                radius: 30
                samples: 16
                z: -1

                // Dimming layer
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.4)
                }
            }

            // The actual content
            TaskViewWidget {
                anchors.fill: parent
                panelWindow: root
            }

            // Key handling to close (Escape) or navigate (Arrows - TODO)
            Item {
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.taskViewOpen = false;
                    }
                }
            }
        }
    }
}
