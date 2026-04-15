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

    property alias inhibit: idleInhibitor.enabled
    property bool autoIdleInhibit: Config.options.autoIdleInhibit
    inhibit: autoIdleInhibit


    Connections {
        target: Persistent
        function onReadyChanged() {
            if (Persistent.isNewHyprlandInstance) {
                Persistent.states.idle.inhibit = Config.options.autoIdleInhibit;
            }
            root.inhibit = Persistent.states.idle.inhibit;
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

    function toggleAutoInhibit(active = null) {
        Config.options.autoIdleInhibit = !Config.options.autoIdleInhibit
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            // Inhibitor requires a "visible" surface
            // Actually not lol
            implicitWidth: 0
            implicitHeight: 0
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
        }
    }
}