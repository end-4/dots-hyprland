pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import "root:/modules/common/functions/object_utils.js" as ObjectUtils
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Qt.labs.platform

/**
 * Manages persistent states across sessions.
 * Run loadStates() once at startup to load the states, then use setState() and getState() to modify and access them.
 */
Singleton {
    id: root
    property string fileDir: Directories.state
    property string fileName: "states.json"
    property string filePath: `${root.fileDir}/${root.fileName}`
    property bool allowWriteback: false

    function getState(nestedKey) {
        let keys = nestedKey.split(".");
        let obj = PersistentStates;
        for (let i = 0; i < keys.length; ++i) {
            if (obj[keys[i]] === undefined) {
                console.error(`[PersistentStateManager] Key "${keys[i]}" not found in PersistentStates`);
                return null;
            }
            obj = obj[keys[i]];
        }
        return obj;
    }

    function setState(nestedKey, value) {
        if (!root.allowWriteback) return;
        let keys = nestedKey.split(".");
        let obj = PersistentStates;
        let parents = [obj];

        // Traverse and collect parent objects
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
            parents.push(obj);
        }

        // Set the value at the innermost key
        obj[keys[keys.length - 1]] = value;

        saveStates()
    }

    function loadStates() {
        stateFileView.reload()
    }

    function saveStates() {
        const plainStates = ObjectUtils.toPlainObject(PersistentStates)
        stateFileView.setText(JSON.stringify(plainStates, null, 2))
    }

    function applyStates(fileContent) {
        try {
            const json = JSON.parse(fileContent);
            ObjectUtils.applyToQtObject(PersistentStates, json);
            root.allowWriteback = true
        } catch (e) {
            console.error("[PersistentStateManager] Error reading file:", e);
            return;
        }
    }

    Timer {
        id: delayedFileRead
        interval: ConfigOptions?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyStates(stateFileView.text())
        }
    }

	FileView { 
        id: stateFileView
        path: root.filePath
        watchChanges: true
        // onFileChanged: {
        //     console.log("[PersistentStateManager] File changed, reloading...")
        //     this.reload()
        //     delayedFileRead.start()
        // }
        onLoadedChanged: {
            const fileContent = stateFileView.text()
            root.applyStates(fileContent)
        }
        onLoadFailed: (error) => {
            console.log("[PersistentStateManager] File not found, creating new file")
            root.saveStates()
        }
    }
}
