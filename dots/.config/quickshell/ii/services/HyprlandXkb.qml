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

    // Hyprland keeps xkb group state per input device and emits one
    // activelayout event per device. Pin tracking to a single device so a
    // spurious event from an unrelated device (e.g. a temporary virtual
    // keyboard created by wtype) can't overwrite what this service reports.
    // Set to a device name from `hyprctl devices -j` to override; leave
    // empty to auto-resolve (Hyprland's main keyboard).
    property string trackedKeyboardOverride: ""
    property string trackedKeyboard: ""
    property bool trackedKeyboardSeen: false

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

    // Find out available layouts, the device to track, and current active layout. Should only be necessary on init
    Process {
        id: fetchLayoutsProc
        running: true
        command: ["hyprctl", "-j", "devices"]

        stdout: StdioCollector {
            id: devicesCollector
            onStreamFinished: {
                const parsedOutput = JSON.parse(devicesCollector.text);
                const keyboards = parsedOutput["keyboards"];
                if (!keyboards || keyboards.length === 0) return;

                // Pin to the override if it resolves, else Hyprland's main keyboard,
                // else just the first one so we always end up with something valid.
                var hyprlandKeyboard = null;
                if (root.trackedKeyboardOverride.length > 0)
                    hyprlandKeyboard = keyboards.find(kb => kb.name === root.trackedKeyboardOverride);
                if (!hyprlandKeyboard)
                    hyprlandKeyboard = keyboards.find(kb => kb.main === true);
                if (!hyprlandKeyboard)
                    hyprlandKeyboard = keyboards[0];

                root.trackedKeyboard = hyprlandKeyboard["name"];
                root.trackedKeyboardSeen = false;
                root.layoutCodes = hyprlandKeyboard["layout"].split(",");
                root.currentLayoutName = hyprlandKeyboard["active_keymap"];
                // console.log("[HyprlandXkb] Fetched | Layouts (multiple: " + (root.layoutCodes.length > 1) + "): "
                //     + root.layoutCodes.join(", ") + " | Active: " + root.currentLayoutName);
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

                // A single physical keyboard can enumerate as several devices (extra
                // HID interfaces for media keys, system keys, NKRO), and each emits
                // its own activelayout event. Anything that briefly registers a new
                // keyboard device (e.g. wtype) can also make Hyprland reset the
                // layout on that device to index 0. Without filtering by device,
                // whichever event arrives last wins, so this can end up reporting a
                // layout that was never actually selected on the keyboard being
                // typed on. Filter to one tracked device once it's been observed at
                // least once; until then, stay permissive so a stale or misspelled
                // override can never freeze this service.
                const prefix = root.trackedKeyboard + ",";
                const fromTracked = root.trackedKeyboard.length > 0 && dataString.startsWith(prefix);

                if (fromTracked) {
                    root.trackedKeyboardSeen = true;
                } else if (root.trackedKeyboardSeen) {
                    return;
                }

                root.currentLayoutName = fromTracked
                    ? dataString.substring(prefix.length)
                    : dataString.substring(dataString.indexOf(",") + 1);

                // Update layout for on-screen keyboard (osk)
                Config.options.osk.layout = root.currentLayoutName.split(" (")[0];
            } else if (event.name == "configreloaded") {
                // Mark layout code list to be updated when config is reloaded
                root.needsLayoutRefresh = true;
            }
        }
    }
}
