import qs.modules.common
import qs.modules.common.widgets
import qs
import QtQuick
import Quickshell.Io
import Quickshell

import "../"

QuickToggle {
    id: root
    toggled: false
    isSupported: false
    customIcon: true
    buttonIcon: "cloudflare-dns-symbolic"

    downAction: () => {
        if (toggled) {
            root.toggled = false;
            Quickshell.execDetached(["warp-cli", "disconnect"]);
        } else {
            root.toggled = true;
            Quickshell.execDetached(["warp-cli", "connect"]);
        }
    }

    Process {
        id: checkWarpCli
        running: true
        command: ["command", "-v", "warp-cli"] // Check if warp-cli is installed
        stdout: StdioCollector {
            id: warpCliCollector
            onStreamFinished: {
                if (warpCliCollector.text.length > 0) {
                    root.isSupported = true; // Only show if warp-cli is found
                    fetchActiveState.running = true; // Proceed to check status
                } else {
                    root.isSupported = false; // Hide if warp-cli is not installed
                }
            }
        }
    }

    Process {
        id: connectProc
        command: ["warp-cli", "connect"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", Translation.tr("Cloudflare WARP"), Translation.tr("Connection failed. Please inspect manually with the <tt>warp-cli</tt> command"), "-a", "Shell"]);
            }
        }
    }

    Process {
        id: registrationProc
        command: ["warp-cli", "registration", "new"]
        onExited: (exitCode, exitStatus) => {
            console.log("Warp registration exited with code and status:", exitCode, exitStatus);
            if (exitCode === 0) {
                connectProc.running = true;
            } else {
                Quickshell.execDetached(["notify-send", Translation.tr("Cloudflare WARP"), Translation.tr("Registration failed. Please inspect manually with the <tt>warp-cli</tt> command"), "-a", "Shell"]);
            }
        }
    }

    Process {
        id: fetchActiveState
        running: false // Only run after confirming warp-cli is installed
        command: ["bash", "-c", "warp-cli status"]
        stdout: StdioCollector {
            id: warpStatusCollector
            onStreamFinished: {
                if (warpStatusCollector.text.includes("Unable")) {
                    registrationProc.running = true;
                } else if (warpStatusCollector.text.includes("Connected")) {
                    root.toggled = true;
                } else if (warpStatusCollector.text.includes("Disconnected")) {
                    root.toggled = false;
                }
            }
        }
    }
}
