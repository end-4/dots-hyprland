pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    id: root

    property bool inhibit: false

    property bool inhibitorStartupDelayElapsed: false

    function restoreState() {
        if (!Persistent.ready)
            return;
        if (!Persistent.isNewHyprlandInstance) {
            root.inhibit = Persistent.states.idle.inhibit;
        } else {
            Persistent.states.idle.inhibit = root.inhibit;
        }
    }

    Component.onCompleted: root.restoreState()

    Connections {
        target: Persistent
        function onReadyChanged() {
            root.restoreState();
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        Persistent.states.idle.inhibit = root.inhibit;
    }

    Timer {
        id: inhibitorStartupTimer
        interval: 1000 // Give the helper surface time to map before enabling idle inhibition.
        repeat: false
        onTriggered: root.inhibitorStartupDelayElapsed = true
    }

    IdleInhibitor {
        id: idleInhibitor
        enabled: root.inhibit && root.inhibitorStartupDelayElapsed
        window: PanelWindow {
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            // Just in case...
            anchors {
                right: true
                bottom: true
            }
            // Make it not interactable
            mask: Region {
                item: null
            }
            Component.onCompleted: inhibitorStartupTimer.restart()
        }
    }
}
