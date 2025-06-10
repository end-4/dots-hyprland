pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common/functions/file_utils.js" as FileUtils
import Qt.labs.platform
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    // XDG Dirs, with "file://"
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    
    // Other dirs used by the shell, without "file://"
    property string favicons: FileUtils.trimFileProtocol(`${Directories.cache}/media/favicons`)
    property string coverArt: FileUtils.trimFileProtocol(`${Directories.cache}/media/coverart`)
    property string booruPreviews: FileUtils.trimFileProtocol(`${Directories.cache}/media/boorus`)
    property string booruDownloads: FileUtils.trimFileProtocol(Directories.pictures  + "/homework")
    property string booruDownloadsNsfw: FileUtils.trimFileProtocol(Directories.pictures + "/homework/🌶️")
    property string latexOutput: FileUtils.trimFileProtocol(`${Directories.cache}/media/latex`)
    property string shellConfig: FileUtils.trimFileProtocol(`${Directories.config}/illogical-impulse`)
    property string shellConfigName: "config.json"
    property string shellConfigPath: `${Directories.shellConfig}/${Directories.shellConfigName}`
    property string todoPath: FileUtils.trimFileProtocol(`${Directories.state}/user/todo.json`)
    property string notificationsPath: FileUtils.trimFileProtocol(`${Directories.cache}/notifications/notifications.json`)
    property string generatedMaterialThemePath: FileUtils.trimFileProtocol(`${Directories.state}/user/generated/colors.json`)
    property string cliphistDecode: FileUtils.trimFileProtocol(`/tmp/quickshell/media/cliphist`)
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${Directories.config}/quickshell/scripts/switchwall.sh`)
    // Cleanup on init
    Component.onCompleted: {
        Hyprland.dispatch(`exec mkdir -p '${shellConfig}'`)
        Hyprland.dispatch(`exec mkdir -p '${favicons}'`)
        Hyprland.dispatch(`exec rm -rf '${coverArt}'; mkdir -p '${coverArt}'`)
        Hyprland.dispatch(`exec rm -rf '${booruPreviews}'; mkdir -p '${booruPreviews}'`)
        Hyprland.dispatch(`exec mkdir -p '${booruDownloads}' && mkdir -p '${booruDownloadsNsfw}'`)
        Hyprland.dispatch(`exec rm -rf '${latexOutput}'; mkdir -p '${latexOutput}'`)
        Hyprland.dispatch(`exec rm -rf '${cliphistDecode}'; mkdir -p '${cliphistDecode}'`)
    }
}
