pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * A service that provides access to Hyprland keybinds.
 */
Singleton {
    id: root
    property string defaultKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/hyprland/keybinds.conf`)
    property string userKeybindConfigPath: FileUtils.trimFileProtocol(`${Directories.config}/hypr/custom/keybinds.conf`)
    property var keybindsModel: []

    function parseKeybindsFile(filepath, source) {
        var content = FileUtils.read(filepath);
        if (!content) {
            return [];
        }
        var items = [];
        var lines = content.split('\n');
        // Regex to capture: 1(bind type), 2(bind content), 3(description)
        var regex = /^\s*(bind[^=]*?)\s*=\s*([^#]+)(?:\s*#\s*(.*))?$/;

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line.length === 0 || line.startsWith('#!')) {
                continue;
            }
            
            var match = line.match(regex);
            if (match) {
                var bindType = match[1].trim();
                var bindContent = match[2].trim();
                var description = match[3] ? match[3].trim() : "";

                var bindParts = bindContent.split(',');
                
                // Hyprland format is: MODS,KEY,DISPATCHER,ARGS
                // We need at least 2 parts for a key and dispatcher. Modifiers can be empty.
                if (bindParts.length < 2) {
                    continue;
                }

                var modifiers = bindParts.shift().trim();
                var key = bindParts.shift().trim();
                var dispatcher = (bindParts.length > 0) ? bindParts.shift().trim() : "";
                var command = (bindParts.length > 0) ? bindParts.join(',').trim() : "";

                // If dispatcher is empty, it's likely a 2-part bind (e.g., MOD,KEY) which is invalid, but we'll handle it gracefully
                if (key === "") {
                    continue;
                }

                items.push({
                    "type": bindType,
                    "modifiers": modifiers,
                    "key": key,
                    "dispatcher": dispatcher,
                    "command": command,
                    "description": description,
                    "source_file": source,
                    "original_line": line
                });
            }
        }
        return items;
    }

    function loadKeybinds() {
        var defaultItems = parseKeybindsFile(defaultKeybindConfigPath, "default");
        var customItems = parseKeybindsFile(userKeybindConfigPath, "custom");
        keybindsModel = defaultItems.concat(customItems);
    }

    function saveKeybind(keybind, isNew) {
        var newBindLine = `${keybind.type} = ${keybind.modifiers},${keybind.key},${keybind.dispatcher},${keybind.command}`;
        if (keybind.description) {
            newBindLine += " # " + keybind.description;
        }

        var currentContent = FileUtils.read(userKeybindConfigPath) || "";
        if (isNew) {
            if (currentContent.length > 0 && !currentContent.endsWith('\n')) {
                currentContent += '\n';
            }
            FileUtils.write(userKeybindConfigPath, currentContent + newBindLine + "\n");
        } else {
            var newContent = currentContent.replace(keybind.original_line, newBindLine);
            FileUtils.write(userKeybindConfigPath, newContent);
        }
        loadKeybinds();
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    function deleteKeybind(keybind) {
        var currentContent = FileUtils.read(userKeybindConfigPath) || "";
        var newContent = currentContent.replace(keybind.original_line, "").replace(/\n\n/g, '\n');
        FileUtils.write(userKeybindConfigPath, newContent.trim());
        loadKeybinds();
        Quickshell.execDetached(["hyprctl", "reload"]);
    }

    Component.onCompleted: {
        loadKeybinds();
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                loadKeybinds();
            }
        }
    }
}