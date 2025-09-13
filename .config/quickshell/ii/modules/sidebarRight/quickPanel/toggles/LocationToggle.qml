import qs.modules.common
import qs.modules.common.widgets
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import "../"

/**
 * This component provides a QuickToggle that manages the systemd service
 * `geoclue.service`.


 */
QuickToggle {
    id: root
    toggled: false
    buttonIcon: "location_on" // Material Design icon for location
    toggleText: "Location"

    // Property to represent the loaded state, used for determining visibility.
    property bool serviceLoaded: false

    // State machine for button interaction
    downAction: () => {
        if (!serviceLoaded && !unmaskProc.running) {
            unmaskProc.running = true;
        } else if (!maskProc.running) {
            maskProc.running = true;
        }
    }

    // altAction: () => {
    //     //could find one a app that works
    //   }

    // Process to unmask the service
    Process {
        id: unmaskProc
        command: ["systemctl", "unmask", "geoclue.service"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // If unmasked successfully, reload daemon and check status
                daemonReloadProc.running = true;
            } else {
                Quickshell.execDetached(["notify-send", "Location Service", "Failed to unmask location service.", "-a", "Shell"]);
                fetchStatusProc.running = true;
            }
        }
    }

    // Process to mask and stop the service immediately
    Process {
        id: maskProc
        command: ["systemctl", "mask", "--now", "geoclue.service"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // Masking success means loaded is false
                root.toggled = false;
                serviceLoaded = false;
            } else {
                Quickshell.execDetached(["notify-send", "Location Service", "Failed to mask location service.", "-a", "Shell"]);
                fetchStatusProc.running = true;
            }
        }
    }

    // Process to reload systemd manager configuration
    Process {
        id: daemonReloadProc
        command: ["systemctl", "daemon-reload"]
        onExited: (exitCode, exitStatus) => {
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
                    serviceLoaded = false;
                } else if (geoclueLoadStateCollector.text.includes("LoadState=loaded")) {
                    // For a D-Bus service, "loaded" means it is ready for activation
                    root.toggled = true;
                    serviceLoaded = true;
                } else {
                    Quickshell.execDetached(["notify-send", "Location Service", "Unable to determine location service status. It may not be installed. Please check manually with 'systemctl status geoclue.service'.", "-a", "Shell"]);
                    root.toggled = false;
                    root.visible = false; // Hide if service isn't even loaded
                    serviceLoaded = false;
                }
            }
        }
    }
}
