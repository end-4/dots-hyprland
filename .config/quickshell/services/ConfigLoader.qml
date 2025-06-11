pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import "root:/modules/common/functions/file_utils.js" as FileUtils
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/object_utils.js" as ObjectUtils
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Qt.labs.platform

/**
 * Loads and manages the shell configuration file.
 * The config file is by default at XDG_CONFIG_HOME/illogical-impulse/config.json.
 * Automatically reloaded when the file changes.
 */
Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property bool firstLoad: true
    property bool preventNextLoad: false
    property var preventNextNotification: false

    function loadConfig() {
        configFileView.reload()
    }

    function applyConfig(fileContent) {
        try {
            if (fileContent.trim() === "") {
                console.warn("[ConfigLoader] Config file is empty, skipping load.");
                return;
            }
            const json = JSON.parse(fileContent);

            ObjectUtils.applyToQtObject(ConfigOptions, json);
            if (root.firstLoad) {
                root.firstLoad = false;
                root.preventNextLoad = true;
                root.saveConfig(); // Make sure new properties are added to the user's config file
            }
        } catch (e) {
            console.error("[ConfigLoader] Error reading file:", e);
            console.log("[ConfigLoader] File content was:", fileContent);
            Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration failed to load")}" "${root.filePath}"`)
            return;

        }
    }

    function setLiveConfigValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = ConfigOptions;
        let parents = [obj];

        // Traverse and collect parent objects
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
            parents.push(obj);
        }

        // Convert value to correct type using JSON.parse when safe
        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        obj[keys[keys.length - 1]] = convertedValue;
    }

    function saveConfig() {
        const plainConfig = ObjectUtils.toPlainObject(ConfigOptions)
        Hyprland.dispatch(`exec echo '${StringUtils.shellSingleQuoteEscape(JSON.stringify(plainConfig, null, 2))}' > '${root.filePath}'`)
    }

    function setConfigValueAndSave(nestedKey, value, preventNextNotification = true) {
        setLiveConfigValue(nestedKey, value);
        root.preventNextNotification = preventNextNotification;
        saveConfig();
    }

    Timer {
        id: delayedFileRead
        interval: ConfigOptions.hacks.arbitraryRaceConditionDelay
        running: false
        onTriggered: {
            if (root.preventNextLoad) {
                root.preventNextLoad = false;
                return;
            }
            if (root.firstLoad) {
                root.applyConfig(configFileView.text())
            } else {
                root.applyConfig(configFileView.text())
                if (!root.preventNextNotification) {
                    // Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration reloaded")}" "${root.filePath}"`)
                } else {
                    root.preventNextNotification = false;
                }
            }
        }
    }

	FileView { 
        id: configFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = configFileView.text()
            delayedFileRead.start()
        }
        onLoadFailed: (error) => {
            if(error == FileViewError.FileNotFound) {
                console.log("[ConfigLoader] File not found, creating new file.")
                root.saveConfig()
                Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration created")}" "${root.filePath}"`)
            } else {
                Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration failed to load")}" "${root.filePath}"`)
            }
        }
    }
}
