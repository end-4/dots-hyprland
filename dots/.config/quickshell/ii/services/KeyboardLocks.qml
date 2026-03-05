pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool capsLockOn: false
    property bool numLockOn: false

    Process {
        id: hyprctl

        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: try {
                const data = JSON.parse(this.text)

                if (!data.keyboards || data.keyboards.length === 0)
                    return

                const kb = data.keyboards.find(k => k.main === true) || data.keyboards[0]

                root.capsLockOn = kb.capsLock
                root.numLockOn = kb.numLock
            } catch(e) {
                console.log("KeyboardLocks parse error:", e)
            }
        }
            
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: hyprctl.running = true
    }
}

