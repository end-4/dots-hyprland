pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import Qt.labs.platform
import QtQuick
import Quickshell

Singleton {
    // XDG Dirs, with "file://"
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    
    // Other dirs used by the shell, without "file://"
    property string assetsPath: Quickshell.shellPath("assets")
    property string scriptPath: Quickshell.shellPath("scripts")
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/quickshell`)
    property string shellConfigName: "oo.json"
    property string shellConfigPath: `${Directories.shellConfig}/${Directories.shellConfigName}`
    property string notificationsPath: FileUtils.trimFileProtocol(`${Directories.cache}/notifications/notifications.json`)
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/switchwall.sh`)
    // Cleanup on init
    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", `${shellConfig}`])
    }
}
