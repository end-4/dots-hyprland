import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

Singleton {
    property string distroName: "Unknown"
    property string distroId: "unknown"
    property string distroIcon: "linux-symbolic"

    Timer {
        interval: 1
        running: true
        repeat: false
        onTriggered: {
            fileOsRelease.reload()
            const textOsRelease = fileOsRelease.text()

            // Extract the friendly name (PRETTY_NAME field, fallback to NAME)
            const prettyNameMatch = textOsRelease.match(/^PRETTY_NAME="(.+?)"/m)
            const nameMatch = textOsRelease.match(/^NAME="(.+?)"/m)
            distroName = prettyNameMatch ? prettyNameMatch[1] : (nameMatch ? nameMatch[1].replace(/Linux/i, "").trim() : "Unknown")

            // Extract the ID (LOGO field, fallback to "unknown")
            const logoMatch = textOsRelease.match(/^LOGO=(.+)$/m)
            distroId = logoMatch ? logoMatch[1].replace(/"/g, "") : "unknown"

            // Update the distroIcon property based on distroId
            switch (distroId) {
                case "arch": distroIcon = "arch-symbolic"; break;
                case "endeavouros": distroIcon = "endeavouros-symbolic"; break;
                case "cachyos": distroIcon = "cachyos-symbolic"; break;
                case "nixos": distroIcon = "nixos-symbolic"; break;
                case "fedora": distroIcon = "fedora-symbolic"; break;
                case "linuxmint":
                case "ubuntu":
                case "zorin":
                case "popos": distroIcon = "ubuntu-symbolic"; break;
                case "debian":
                case "raspbian":
                case "kali": distroIcon = "debian-symbolic"; break;
                default: distroIcon = "linux-symbolic"; break;
            }
        }
    }

    FileView {
        id: fileOsRelease
        path: "/etc/os-release"
    }
}