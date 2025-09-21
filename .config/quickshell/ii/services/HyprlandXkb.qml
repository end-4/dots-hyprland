pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common

/**
 * Exposes the active Hyprland Xkb keyboard layout name and code for indicators.
 */
Singleton {
    id: root
    // You can read these
    property list<string> layoutCodes: []
    property var cachedLayoutCodes: ({})
    property string currentLayoutName: ""
    property string currentLayoutCode: ""
    // For the service
    property var baseLayoutFilePath: "/usr/share/X11/xkb/rules/base.lst"
    property bool needsLayoutRefresh: false

    // Update the layout code according to the layout name (Hyprland gives the name not the code)
    onCurrentLayoutNameChanged: root.updateLayoutCode()
    function updateLayoutCode() {
        if (cachedLayoutCodes.hasOwnProperty(currentLayoutName)) {
            root.currentLayoutCode = cachedLayoutCodes[currentLayoutName];
        } else {
            getLayoutProc.running = true;
        }
    }

    // Get the layout code from the base.lst file by grabbing the line with the current layout name
    Process {
        id: getLayoutProc
        command: ["cat", root.baseLayoutFilePath]

        stdout: StdioCollector {
            id: layoutCollector

            onStreamFinished: {
                const lines = layoutCollector.text.split("\n");
                const targetDescription = root.currentLayoutName;
                const foundLine = lines.find(line => {
                    // Skip comment lines and empty lines
                    if (!line.trim() || line.trim().startsWith('!'))
                        return false;

                    // Match layout: (whitespace + ) key + whitespace + description
                    const matchLayout = line.match(/^\s*(\S+)\s+(.+)$/);
                    if (matchLayout && matchLayout[2] === targetDescription) {
                        root.cachedLayoutCodes[matchLayout[2]] = matchLayout[1];
                        root.currentLayoutCode = matchLayout[1];
                        return true;
                    }

                    // Match variant: (whitespace + ) variant + whitespace + key + whitespace + description
                    const matchVariant = line.match(/^\s*(\S+)\s+(\S+)\s+(.+)$/);
                    if (matchVariant && matchVariant[3] === targetDescription) {
                        const complexLayout = matchVariant[2] + matchVariant[1];
                        root.cachedLayoutCodes[matchVariant[3]] = complexLayout;
                        root.currentLayoutCode = complexLayout;
                        return true;
                    }
                    
                    return false;
                });
                // console.log("[HyprlandXkb] Found line:", foundLine);
                // console.log("[HyprlandXkb] Layout:", root.currentLayoutName, "| Code:", root.currentLayoutCode);
                // console.log("[HyprlandXkb] Cached layout codes:", JSON.stringify(root.cachedLayoutCodes, null, 2));
            }
        }
    }

    // Find out available layouts and current active layout. Should only be necessary on init
    Process {
        id: fetchLayoutsProc
        running: true
        command: ["hyprctl", "-j", "devices"]

        stdout: StdioCollector {
            id: devicesCollector
            onStreamFinished: {
                const parsedOutput = JSON.parse(devicesCollector.text);
                const hyprlandKeyboard = parsedOutput["keyboards"].find(kb => kb.main === true);
                root.layoutCodes = hyprlandKeyboard["layout"].split(",");
                root.currentLayoutName = hyprlandKeyboard["active_keymap"];
                // console.log("[HyprlandXkb] Fetched | Layouts (multiple: " + (root.layouts.length > 1) + "): "
                //     + root.layouts.join(", ") + " | Active: " + root.currentLayoutName);
            }
        }
    }

    // Update the layout name when it changes
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                if (root.needsLayoutRefresh) {
                    root.needsLayoutRefresh = false;
                    fetchLayoutsProc.running = true;
                }

                // If there's only one layout, the updated layout is always the same
                if (root.layoutCodes.length <= 1) return;

                // Update when layout might have changed
                const dataString = event.data;
                root.currentLayoutName = dataString.split(",")[1];

                // Update layout for on-screen keyboard (osk)
                Config.options.osk.layout = root.currentLayoutName;
            } else if (event.name == "configreloaded") {
                // Mark layout code list to be updated when config is reloaded
                root.needsLayoutRefresh = true;
            }
        }
    }
}
