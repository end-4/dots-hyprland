import qs
import qs.singletons
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    // Open states
    property bool barOpen: true
    property bool launcherOpen: true

    // Smooth screen zoom
    IpcHandler {
		target: "zoom"

		function zoomIn() {
            screenZoom = Math.min(screenZoom + 0.4, 3.0)
        }

        function zoomOut() {
            screenZoom = Math.max(screenZoom - 0.4, 1)
        }
	}

    property real screenZoom: 1

    onScreenZoomChanged: {
        Quickshell.execDetached(["hyprctl", "keyword", "cursor:zoom_factor", root.screenZoom.toString()]);
    }

    Behavior on screenZoom {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}