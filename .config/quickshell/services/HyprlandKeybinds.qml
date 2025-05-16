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
    property var defaultKeybinds: []
    property var userKeybinds: []
    property var keybinds: ({
        children: [
            ...defaultKeybinds.children,
            ...userKeybinds.children,
        ]
    })

    // onKeybindsChanged: {
    //     console.log("[CheatsheetKeybinds] Keybinds changed:", JSON.stringify(keybinds, null, 2))
    // }   

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                getDefaultKeybinds.running = true
                getUserKeybinds.running = true
            }
        }
    }

    Process {
        id: getDefaultKeybinds
        running: true
        command: [FileUtils.trimFileProtocol(`${XdgDirectories.config}/quickshell/scripts/hyprland/get_keybinds.py`), 
            "--path", FileUtils.trimFileProtocol(`${XdgDirectories.config}/hypr/hyprland/keybinds.conf`),]
        
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.defaultKeybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }

    Process {
        id: getUserKeybinds
        running: true
        command: [FileUtils.trimFileProtocol(`${XdgDirectories.config}/quickshell/scripts/hyprland/get_keybinds.py`), 
            "--path", FileUtils.trimFileProtocol(`${XdgDirectories.config}/hypr/custom/keybinds.conf`),]
        
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.userKeybinds = JSON.parse(data)
                } catch (e) {
                    console.error("[CheatsheetKeybinds] Error parsing keybinds:", e)
                }
            }
        }
    }
}

