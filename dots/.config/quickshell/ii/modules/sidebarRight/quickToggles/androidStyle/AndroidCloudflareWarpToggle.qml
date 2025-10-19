import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Cloudflare WARP")

    toggled: false
    buttonIcon: "cloud_lock"
    
    onClicked: {
        if (toggled) {
            root.toggled = false
            Quickshell.execDetached(["warp-cli", "disconnect"])
        } else {
            root.toggled = true
            Quickshell.execDetached(["warp-cli", "connect"])
        }
    }

    Process {
        id: connectProc
        command: ["warp-cli", "connect"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", 
                    Translation.tr("Cloudflare WARP"), 
                    Translation.tr("Connection failed. Please inspect manually with the <tt>warp-cli</tt> command")
                    , "-a", "Shell"
                ])
            }
        }
    }

    Process {
        id: registrationProc
        command: ["warp-cli", "registration", "new"]
        onExited: (exitCode, exitStatus) => {
            console.log("Warp registration exited with code and status:", exitCode, exitStatus)
            if (exitCode === 0) {
                connectProc.running = true
            } else {
                Quickshell.execDetached(["notify-send", 
                    Translation.tr("Cloudflare WARP"), 
                    Translation.tr("Registration failed. Please inspect manually with the <tt>warp-cli</tt> command"),
                    "-a", "Shell"
                ])
            }
        }
    }

    Process {
        id: fetchActiveState
        running: true
        command: ["bash", "-c", "warp-cli status"]
        stdout: StdioCollector {
            id: warpStatusCollector
            onStreamFinished: {
                if (warpStatusCollector.text.length > 0) {
                    root.visible = true
                }
                if (warpStatusCollector.text.includes("Unable")) {
                    registrationProc.running = true
                } else if (warpStatusCollector.text.includes("Connected")) {
                    root.toggled = true
                } else if (warpStatusCollector.text.includes("Disconnected")) {
                    root.toggled = false
                }
            }
        }
    }
    StyledToolTip {
        text: Translation.tr("Cloudflare WARP (1.1.1.1)")
    }
}
