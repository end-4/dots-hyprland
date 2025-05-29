import "root:/"
import "root:/services"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/icons.js" as Icons
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

RowLayout {
    readonly property list<var> windowList: HyprlandData.windowList
    readonly property list<string> apps: {
        let uniqueClasses = new Set()
        for (let window of windowList) {
            if (window.class && window.class.trim() !== "") {
                uniqueClasses.add(window.class)
            }
        }
        return Array.from(uniqueClasses)
    }
    readonly property var windowsByApp: {
        let grouped = {}
        for (let window of windowList) {
            if (window.class && window.class.trim() !== "") {
                if (!grouped[window.class]) {
                    grouped[window.class] = []
                }
                grouped[window.class].push(window)
            }
        }
        return grouped
    }

    Repeater {
        model: apps
        delegate: DockButton {
            required property string modelData
            property int lastFocusedIndex: -1
            contentItem: IconImage {
                source: Quickshell.iconPath(Icons.noKnowledgeIconGuess(modelData), "image-missing")
            }
            onClicked: () => {
                lastFocusedIndex = (lastFocusedIndex + 1) % windowsByApp[modelData].length
                const targetWindow = windowsByApp[modelData][lastFocusedIndex];
                const targetAddress = targetWindow.address;
                Hyprland.dispatch(`focuswindow address:${targetAddress}`);
            }
        }
    }
}