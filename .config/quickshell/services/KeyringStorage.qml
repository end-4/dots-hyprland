pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

Singleton {
    id: root

    property var keyringData: {}
    // onKeyringDataChanged: {
    //     console.log("[KeyringStorage] Keyring data changed:", JSON.stringify(root.keyringData));
    // }
    
    property var properties: {
        "application": "illogical-impulse",
        "explanation": "For storing API keys and other sensitive information",
    }
    property var propertiesAsArgs: Object.keys(root.properties).reduce(
        function(arr, key) {
            return arr.concat([key, root.properties[key]]);
        }, []
    )
    property string keyringLabel: "illogical-impulse Safe Storage"

    function setNestedField(path, value) {
        if (!root.keyringData) root.keyringData = {};
        let keys = path
        let obj = root.keyringData;
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
        }
        obj[keys[keys.length - 1]] = value;
        // console.log("[KeyringStorage] Updated keyring data:", JSON.stringify(root.keyringData));
        saveKeyringData()
    }

    function fetchKeyringData() {
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
                stdinEnabled = false // End input stream
            }
        }
    }

    Process {
        id: getData
        command: [ // We need to use echo for a newline so splitparser does parse
            "bash", "-c", `echo $(secret-tool lookup 'application' 'illogical-impulse')`,
        ]
        stdout: SplitParser {
            onRead: data => {
                if(data.length === 0) return;
                try {
                    root.keyringData = JSON.parse(data);
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
            if (exitCode !== 0) {
                console.error("[KeyringStorage] Failed to get keyring data, reinitializing.");
                root.keyringData = {};
                saveKeyringData()
            }
        }
    }
    
}
