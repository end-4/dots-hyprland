pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    signal keyPressed(int keycode)
    signal keyReleased(int keycode)

    property bool active: false

    onActiveChanged: {
        if (active) {
            monitor.running = true;
        } else {
            monitor.running = false;
        }
    }

    Process {
        id: monitor
        command: ["python3", `${Directories.scriptPath}/keyboard_monitor.py`]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const event = JSON.parse(data);
                    if (event.error) {
                        console.warn("[PhysicalKeyboard]", event.error);
                        return;
                    }
                    if (event.status === "ready") {
                        return;
                    }
                    if (event.keycode !== undefined) {
                        if (event.pressed) {
                            root.keyPressed(event.keycode);
                        } else {
                            root.keyReleased(event.keycode);
                        }
                    }
                } catch (e) {
                    console.warn("[PhysicalKeyboard] Parse error:", e);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (root.active) {
                console.warn("[PhysicalKeyboard] Monitor exited unexpectedly with code", exitCode, "- restarting");
                monitor.running = true;
            }
        }
    }
}
