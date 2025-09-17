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
    toggleText: "Warp"
    halfToggled: false
    stateText: "Disconnected"
    downAction: () => {
        if (toggled) {
            root.halfToggled = false;
            disconnectProc.running = true;
        } else {
            root.halfToggled = true;
            connectProc.running = true;
        }
    }

    Process {
        id: checkWarpCli
        running: true
        command: ["bash", "-c", "command -v warp-cli"] // Check if warp-cli is installed
        stdout: StdioCollector {
            id: warpCliCollector
            onStreamFinished: {
                if (warpCliCollector.text.length > 0) {
                    // console.warn("Warp Supported");
                    root.isSupported = true; // Only show if warp-cli is found
                    fetchActiveState.running = true; // Proceed to check status
                } else {
                    // console.warn("Warp UnSupported");
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

            // fetchActiveState.exec(["bash", "-c" , "warp-cli", "status"])

            fetchActiveState.running = true;
        }
    }
    Process {
        id: disconnectProc
        command: ["warp-cli", "disconnect"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", Translation.tr("Cloudflare WARP"), Translation.tr("Failed to disconnect. Please inspect manually with the <tt>warp-cli</tt> command"), "-a", "Shell"]);
                root.stateText = "Failed";
            }
            // fetchActiveState.exec(["bash", "-c" , "warp-cli status"])
            fetchActiveState.running = true;
        }
    }

    Process {
        id: registrationProc
        command: ["warp-cli", "registration", "new"]
        onExited: (exitCode, exitStatus) => {
            console.log("Warp registration exited with code and status:", exitCode, exitStatus);
            if (exitCode === 0) {
                connectProc.running = true;
                root.stateText = "Connecting";
            } else {
                Quickshell.execDetached(["notify-send", Translation.tr("Cloudflare WARP"), Translation.tr("Registration failed. Please inspect manually with the <tt>warp-cli</tt> command"), "-a", "Shell"]);
            }
        }
    }

    Process {
        id: fetchActiveState
        command: ["bash", "-c", "warp-cli status"]
        stdout: StdioCollector {
            id: warpStatusCollector
            onStreamFinished: {
                console.warn("Fetching data Warp", warpStatusCollector.text);
                if (warpStatusCollector.text.includes("Unable")) {
                    registrationProc.running = true;
                    root.stateText = "Registering";
                } else if (warpStatusCollector.text.includes("Connected")) {
                    root.toggled = true;
                    root.stateText = "Connected";
                } else if (warpStatusCollector.text.includes("Disconnected")) {
                    root.toggled = false;
                    root.stateText = "Disconnected";
                } else {
                    root.toggled = false;
                    root.stateText = warpStatusCollector.text.split(/[ \n]+/)[2] || "Checking";
                    timer.start();
                }
            }
        }
    }

    // Why this timer ?
    // after running connectProc and setting fetchActiveState to true it used to check the status too early which generated empty string.
    // So I decided to keep executing fetchActiveState until a valid stable state either connected or disconnected is determined.
    // Directly calling fetchActiveState from within itself was too fast and caused 100s of calls.
    // Also tried to use the onRunningChanged to run the process in loop [as in the quickshell documentation] but didn't work

    Timer {
        id: timer
        interval: 300
        repeat: false
        onTriggered: {
            // Re-execute the process after the delay
            fetchActiveState.exec(["bash", "-c", "warp-cli status"]);
        }
    }
}
