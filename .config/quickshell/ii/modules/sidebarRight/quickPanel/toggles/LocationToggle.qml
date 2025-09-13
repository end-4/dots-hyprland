import qs.modules.common
import qs.modules.common.widgets
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

/**
 * Location toggle button for QuickShell panel, using QuickToggle.
 * Toggles GeoClue location service when clicking the icon (downAction).
 * Opens location settings when clicking the text (altAction).
 */
QuickToggle {
    id: root
    toggled: false
    buttonIcon: "location_on" // Material Design icon for location
    toggleText: "Location"

    downAction: () => {
        if (toggled && !stopProc.running) {
            root.toggled = false
            stopProc.running = true
        } else if (!startProc.running){
            root.toggled = true
            startProc.running = true
        }
    }

    altAction: () => {
        // Open location settings (adjust for your desktop environment)
        Quickshell.execDetached(["cosmic-setting"])
    }

    Process {
        id: startProc
        command: ["systemctl",  "start", "geoclue.service"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send",
                    "Location Service",
                    "Failed to start location service. Please check manually with 'systemctl status geoclue.service'",
                    "-a", "Shell"
                ])
                root.toggled = false
                fetchActiveState.running = true // Re-check state
            }
        }
    }

    Process {
        id: stopProc
        command: ["systemctl", "stop", "geoclue.service"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send",
                    "Location Service",
                    "Failed to stop location service. Please check manually with 'systemctl --user status geoclue.service'",
                    "-a", "Shell"
                ])
                root.toggled = true
                fetchActiveState.running = true // Re-check state
            }
        }
    }

    Process {
        id: fetchActiveState
        running: true
        command: ["systemctl",  "is-active", "geoclue.service"]
        stdout: StdioCollector {
            id: geoclueStatusCollector
            onStreamFinished: {
                if (geoclueStatusCollector.text.length > 0) {
                    root.visible = true
                }
                if (geoclueStatusCollector.text.includes("active")) {
                    root.toggled = true
                } else if (geoclueStatusCollector.text.includes("inactive") || geoclueStatusCollector.text.includes("failed")) {
                    root.toggled = false
                } else {
                    // If status is unclear, notify user
                    Quickshell.execDetached(["notify-send",
                        "Location Service",
                        "Unable to determine location service status. Please check manually with 'systemctl --user status geoclue.service'",
                        "-a", "Shell"
                    ])
                }
            }
        }
    }
}
