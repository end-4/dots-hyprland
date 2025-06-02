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
 * Automatically reloaded when the file changes, but does not provide a way to save changes.
 */
Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property bool firstLoad: true

    function loadConfig() {
        configFileView.reload()
    }

    function applyConfig(fileContent) {
        try {
            const json = JSON.parse(fileContent);

            ObjectUtils.applyToQtObject(ConfigOptions, json);
            if (root.firstLoad) {
                root.firstLoad = false;
            } else {
                Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration reloaded")}" "${root.filePath}"`)
            }
        } catch (e) {
            console.error("[ConfigLoader] Error reading file:", e);
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

        console.log(parents.join("."));
        console.log(`[ConfigLoader] Setting live config value: ${nestedKey} = ${convertedValue}`);
        obj[keys[keys.length - 1]] = convertedValue;
    }

    function saveConfig() {
        const plainConfig = ObjectUtils.toPlainObject(ConfigOptions)
        Hyprland.dispatch(`exec echo '${StringUtils.shellSingleQuoteEscape(JSON.stringify(plainConfig, null, 2))}' > '${root.filePath}'`)
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
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            console.log("[ConfigLoader] File changed, reloading...")
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
                root.saveConfig()
                Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration created")}" "${root.filePath}"`)
            } else {
                Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration failed to load")}" "${root.filePath}"`)
            }
        }
    }
}
