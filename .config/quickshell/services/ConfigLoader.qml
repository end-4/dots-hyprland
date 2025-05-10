pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Qt.labs.platform

Singleton {
    id: root
    property string fileDir: `${StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]}/illogical-impulse`
    property string fileName: "config.json"
    property string filePath: `${root.fileDir}/${root.fileName}`

    function toPlainObject(qtObj) {
        if (qtObj === null || typeof qtObj !== "object") return qtObj;

        // Handle arrays
        if (Array.isArray(qtObj)) {
            return qtObj.map(toPlainObject);
        }

        const result = ({});
        for (let key in qtObj) {
            if (
                typeof qtObj[key] !== "function" &&
                !key.startsWith("objectName") &&
                !key.startsWith("children") &&
                !key.startsWith("object") &&
                !key.startsWith("parent") &&
                !key.startsWith("metaObject") &&
                !key.startsWith("destroyed") &&
                !key.startsWith("reloadableId")
            ) {
                result[key] = toPlainObject(qtObj[key]);
            }
        }
        return result;
    }

    function loadConfig() {
        configFileView.reload()
    }

    function applyConfig(fileContent) {
        const json = JSON.parse(fileContent);

        function applyToQtObject(qtObj, jsonObj) {
            if (!qtObj || typeof jsonObj !== "object" || jsonObj === null) return;

            for (let key in jsonObj) {
                if (!qtObj.hasOwnProperty(key)) continue;

                // Check if the property is a QtObject (not a value)
                const value = qtObj[key];
                const jsonValue = jsonObj[key];

                // If it's an object and not an array, recurse
                if (value && typeof value === "object" && !Array.isArray(value)) {
                    applyToQtObject(value, jsonValue);
                } else {
                    // Otherwise, assign the value
                    qtObj[key] = jsonValue;
                }
            }
        }

        applyToQtObject(ConfigOptions, json);
    }

    Timer {
        id: delayedFileRead
        interval: ConfigOptions.hacks.arbitraryRaceConditionDelay
        repeat: false
        running: false
        onTriggered: {
            root.applyConfig(configFileView.text())
        }
    }

	FileView { 
        id: configFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = configFileView.text()
            root.applyConfig(fileContent)
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[ConfigLoader] File not found, creating new file.")
                // Apply ConfigOptions json to file
                const plainConfig = toPlainObject(ConfigOptions)
                configFileView.setText(JSON.stringify(plainConfig, null, 2))
            } else {
                Hyprland.dispatch(`exec notify-send "Failed to load config file at ${root.filePath}"`)
            }
        }
    }
}
