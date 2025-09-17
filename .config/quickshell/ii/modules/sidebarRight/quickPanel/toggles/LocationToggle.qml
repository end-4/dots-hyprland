import qs.modules.common
import qs.modules.common.widgets
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

/**
  This component provides a QuickToggle that manages the systemd service
  `geoclue.service`.
 */
QuickToggle {
    id: root
    toggled: false
    buttonIcon: "location_on"
    toggleText: "Location"
    isSupported: false

    downAction: () => {
        if (toggled && !maskProc.running) {
            maskProc.running = true;
        } else if (!unmaskProc.running) {
            unmaskProc.running = true;
        }
    }

    Process {
        id: unmaskProc
        command: ["systemctl", "unmask", "geoclue.service"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", "Location Service", "Failed to unmask location service.", "-a", "Shell"]);
            }
                fetchStatusProc.running = true;
        }
    }

    // Process to mask and stop the service immediately
    Process {
        id: maskProc
        command: ["systemctl", "mask", "--now", "geoclue.service"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", "Location Service", "Failed to mask location service.", "-a", "Shell"]);
            }
              fetchStatusProc.running = true;
        }
    }

    // Process to fetch the service status and update the UI
    Process {
        id: fetchStatusProc
        running: true
        command: ["systemctl", "show", "--no-pager", "-p", "LoadState", "geoclue.service"]
        stdout: StdioCollector {
            id: geoclueLoadStateCollector
            onStreamFinished: () => {
                if (geoclueLoadStateCollector.text.includes("LoadState=masked")) {
                    root.toggled = false;
                    isSupported = true;

                } else if (geoclueLoadStateCollector.text.includes("LoadState=loaded")) {
                    // For a D-Bus service, "loaded" means it is ready for activation
                    root.toggled = true;
                    isSupported = true;

                } else {
                    Quickshell.execDetached(["notify-send", "Location Service", "Unable to determine location service status. It may not be installed. Please check manually with 'systemctl status geoclue.service'.", "-a", "Shell"]);
                    root.toggled = false
                    isSupported = false;
                }
            }
        }
    }
}
