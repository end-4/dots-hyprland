pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import "root:/modules/common/functions/file_utils.js" as FileUtils
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root
    property var keybinds: []

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            console.log("[CheatsheetKeybinds] Event:", event.name)
            if (event.name == "configreloaded") {
                getKeybinds.running = true
            }
        }
    }

    Process {
        id: getKeybinds
        running: true
        command: [FileUtils.trimFileProtocol(`${XdgDirectories.config}/quickshell/scripts/hyprland/get_keybinds.py`), 
            "--path", FileUtils.trimFileProtocol(`${XdgDirectories.config}/hypr/hyprland/keybinds.conf`),]
        
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.keybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }
}

