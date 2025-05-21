pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common"
import "root:/modules/common/functions/file_utils.js" as FileUtils
import "root:/modules/common/functions/object_utils.js" as ObjectUtils
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Qt.labs.platform

Singleton {
    id: root
    property string fileDir: `${XdgDirectories.config}/illogical-impulse`
    property string fileName: "config.json"
    property string filePath: FileUtils.trimFileProtocol(`${root.fileDir}/${root.fileName}`)
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
                const plainConfig = ObjectUtils.toPlainObject(ConfigOptions)
                configFileView.setText(JSON.stringify(plainConfig, null, 2))
                Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration created")}" "${root.filePath}"`)
            } else {
                Hyprland.dispatch(`exec notify-send "${qsTr("Shell configuration failed to load")}" "${root.filePath}"`)
            }
        }
    }
}
