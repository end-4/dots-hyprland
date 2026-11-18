pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.ii.island

// Flashes the new default output device when it changes (headphones vs speakers).
Item {
    id: root

    // Output nodes whose name or description reveal a headset/earbud device.
    readonly property var headphoneRe: /headphone|headset|earphone|earbud|\bbuds?\b/i

    // Last sink we saw; a change to the same node is not a switch.
    property var lastSink: null
    // Until we have seen one sink, the first non-null value is the startup value.
    property bool seeded: false

    Component.onCompleted: {
        if (Audio.sink) {
            root.seeded = true;
            root.lastSink = Audio.sink;
        }
    }

    Connections {
        target: Audio
        function onSinkChanged() {
            const sink = Audio.sink;
            if (!sink)
                return;
            if (!root.seeded) {
                root.seeded = true;
                root.lastSink = sink;
                return;
            }
            if (sink === root.lastSink)
                return;
            root.lastSink = sink;

            const name = Audio.friendlyDeviceName(sink);
            const hints = [name, sink.description, sink.name, sink.nickname].join(" ");
            const headphones = root.headphoneRe.test(hints);
            // A script just announced this switch itself through `island flash`: don't repeat it.
            if (Date.now() - IslandState.lastExternalFlash < 2500)
                return;
            IslandState.flash(headphones ? "headphones" : "speaker", name, { ms: 1800 });
        }
    }
}
