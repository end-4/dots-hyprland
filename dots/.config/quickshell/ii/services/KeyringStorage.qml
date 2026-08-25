pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import Quickshell;
import Quickshell.Io;
import QtQuick;

/**
 * For storing sensitive data in the keyring.
 * Use this for small data only, since it stores a JSON of the contents directly and doesn't use a database.
 */
Singleton {
    id: root

    signal dataChanged()

    property bool loaded: false
    property var keyringData: ({})
    // Writes that arrived before the initial fetch finished. Replayed by
    // flushPendingWrites() once the real contents are in memory.
    property var pendingWrites: []
    
    property var properties: {
        "application": "illogical-impulse",
        "explanation": Translation.tr("For storing API keys and other sensitive information"),
    }
    property var propertiesAsArgs: Object.keys(root.properties).reduce(
        function(arr, key) {
            return arr.concat([key, root.properties[key]]);
        }, []
    )
    property string keyringLabel: Translation.tr("%1 Safe Storage").arg("illogical-impulse")

    function setNestedField(path, value) {
        // saveKeyringData() serialises the entire keyring blob, and
        // `secret-tool store` replaces the stored value outright - there is no
        // merge on the storage side. Until the initial fetch completes,
        // keyringData is still the empty default, so saving now would persist a
        // blob containing only this one field and destroy every other secret
        // already stored. Queue the write and replay it once loaded instead.
        if (!root.loaded) {
            root.pendingWrites.push({ path: path, value: value });
            root.fetchKeyringData();
            return;
        }
        root.applyNestedField(path, value);
        root.saveKeyringData();
    }

    function applyNestedField(path, value) {
        if (!root.keyringData) root.keyringData = {};
        let keys = path;
        let obj = root.keyringData;
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

        // Reassign each parent object from the bottom up to trigger change notifications
        for (let i = keys.length - 2; i >= 0; --i) {
            let parent = parents[i];
            let key = keys[i];
            // Shallow clone to change object identity (spread replaced with Object.assign)
            parent[key] = Object.assign({}, parent[key]);
        }

        // Finally, reassign root.keyringData to trigger top-level change
        root.keyringData = Object.assign({}, root.keyringData);
    }

    function flushPendingWrites() {
        if (root.pendingWrites.length === 0) return;
        const writes = root.pendingWrites;
        root.pendingWrites = [];
        for (let i = 0; i < writes.length; ++i) {
            root.applyNestedField(writes[i].path, writes[i].value);
        }
        root.saveKeyringData();
    }

    function fetchKeyringData() {
        if (getData.running) return;
        // console.log("[KeyringStorage] Fetching keyring data...");
        // console.log("[KeyringStorage] getData command:'" + getData.command.join("' '") + "'");
        getData.running = true;
    }

    function saveKeyringData() {
        saveData.stdinEnabled = true;
        saveData.running = true;
    }

    Process {
        id: saveData
        command: [
            "secret-tool", "store", "--label=" + keyringLabel,
            ...propertiesAsArgs,
        ]
        onRunningChanged: {
            if (saveData.running) {
                // console.log("[KeyringStorage] Saving with command: '" + saveData.command.join("' '") + "'");
                saveData.write(JSON.stringify(root.keyringData));
                root.dataChanged()
                stdinEnabled = false // End input stream
            }
        }
    }

    Process {
        id: getData
        command: [ // We need to use echo for a newline so splitparser does parse
            "bash", "-c", `${Directories.scriptPath}/keyring/try_lookup.sh 2> /dev/null`,
        ]
        stdout: StdioCollector {
            id: keyringDataOutputCollector
            onStreamFinished: {
                const data = keyringDataOutputCollector.text;
                if (data.length === 0 || !data.startsWith("{")) return;
                try {
                    root.keyringData = JSON.parse(data);
                    root.dataChanged();
                    // console.log("[KeyringStorage] Keyring data fetched:", JSON.stringify(root.keyringData));
                } catch (e) {
                    console.error("[KeyringStorage] Failed to get keyring data, reinitializing.");
                    root.keyringData = {};
                    saveKeyringData()
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            // console.log("[KeyringStorage] Keyring data fetch process exited with code:", exitCode);
            if (exitCode === 1) {
                console.error("[KeyringStorage] Entry not found, initializing.");
                root.keyringData = {};
                if (root.pendingWrites.length === 0) saveKeyringData()
            }
            if (exitCode !== 2) {
                root.loaded = true;
                root.flushPendingWrites();
            }
        }
    }
    
}
