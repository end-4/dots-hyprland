import "root:/modules/common"
import "root:/modules/common/widgets"
import "../"
import QtQuick
import Quickshell.Io
import Quickshell
import Quickshell.Hyprland

QuickToggleButton {
    id: root
    toggled: false
    visible: false
    
    contentItem: CustomIcon {
        id: distroIcon
        source: 'cloudflare-dns-symbolic'

        anchors.centerIn: parent
        height: 16
        colorize: true
        color: root.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

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
                Quickshell.execDetached(["notify-send", "Cloudflare WARP", "Connection failed. Please inspect manually with the <tt>warp-cli</tt> command", "-a", "Shell"])
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
                Quickshell.execDetached(["notify-send", "Cloudflare WARP", "Registration failed. Please inspect manually with the <tt>warp-cli</tt> command", "-a", "Shell"])
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
                    console.log("Showing warp")
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
        content: qsTr("Cloudflare WARP (1.1.1.1)")
    }
}
