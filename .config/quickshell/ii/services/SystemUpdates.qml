pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root

    readonly property int fetchInterval: Config.options.systemControls.fetchInterval * 60 * 1000
    property bool active: Config.options.systemControls.showUpdates
    property string updatesAvail: ""
    property string lastFetch: DateTime.time

    function getUpdates() {
        fetcher.running = true;
    }

    Process {
        id: fetcher

        command: ["bash", "-c", `${Directories.scriptPath}/system/updates.sh`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) {
                    root.updatesAvail = "--"
                    return;
                } else {
                    root.updatesAvail = text
                }
                root.lastFetch = DateTime.time
            }
        }
    }

    Timer {
        running: root.active
        repeat: root.active
        interval: root.fetchInterval
        triggeredOnStart: root.active
        onTriggered: getUpdates()
    }
}
