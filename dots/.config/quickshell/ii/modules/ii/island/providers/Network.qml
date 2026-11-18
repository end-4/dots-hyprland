pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.services
import qs.modules.ii.island

// Connectivity watcher using NetworkManager's own check. Shows "Offline" or
// "Limited connection" in the pill, and flashes once when the link is back.
Item {
    id: root

    property bool offline: false   // last reading was none or limited
    property string shown: ""      // state the pill currently reflects, to skip redundant updates

    function onReading(state) {
        if (state === "none" || state === "limited") {
            root.offline = true;
            if (root.shown !== state) {
                root.shown = state;
                IslandState.setActivity("offline", {
                    icon: "wifi_off",
                    text: state === "none" ? Translation.tr("Offline") : Translation.tr("Limited connection"),
                    color: String(Appearance.colors.colError),
                    priority: 90
                });
            }
        } else if (state === "full") {
            if (root.offline) {
                root.offline = false;
                root.shown = "";
                IslandState.clearActivity("offline");
                IslandState.flash("wifi", Translation.tr("Back online"), { color: "#3fb950", ms: 2000 });
            }
        }
        // portal / unknown / empty: nmcli cannot tell yet, so keep the previous verdict.
    }

    Process {
        id: check
        command: ["nmcli", "-t", "-f", "CONNECTIVITY", "general"]
        stdout: StdioCollector {
            onStreamFinished: root.onReading(text.trim())
        }
    }

    // Needs NetworkManager's nmcli; without it the provider stays idle (checked once).
    property bool hasNmcli: false
    Process {
        running: true
        command: ["sh", "-c", "command -v nmcli"]
        onExited: (code, status) => root.hasNmcli = code === 0
    }

    // Faster while offline so the "Back online" flash is prompt.
    Timer {
        interval: root.offline ? 5000 : 15000
        running: root.hasNmcli
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!check.running)
                check.running = true;
        }
    }
}
