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
    property string scriptPath: FileUtils.trimFileProtocol(`${Directories.config}/quickshell/scripts`)
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
    property string wallpaperSwitchScriptPath: FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/switchwall.sh`)
    property string defaultAiPrompts: FileUtils.trimFileProtocol(`${Directories.config}/quickshell/defaults/ai/prompts`)
    property string userAiPrompts: FileUtils.trimFileProtocol(`${Directories.shellConfig}/ai/prompts`)
    // Cleanup on init
    Component.onCompleted: {
        const safeCleanupScript = FileUtils.trimFileProtocol(`${Directories.scriptPath}/safe_cleanup_dir.sh`);

        // Ensure script is executable (though it should be set by deployment)
        // Quickshell.execDetached(["chmod", "+x", safeCleanupScript]); // Consider if this is needed or handled elsewhere

        // Directories to ensure exist (mkdir -p only)
        Quickshell.execDetached(["mkdir", "-p", shellConfig]);
        Quickshell.execDetached(["mkdir", "-p", favicons]);
        Quickshell.execDetached(["mkdir", "-p", booruDownloads]);
        Quickshell.execDetached(["mkdir", "-p", booruDownloadsNsfw]);

        // Directories to be cleaned up (rm -rf path; mkdir -p path) via the safe script
        // Note: safe_cleanup_dir.sh handles both rm and mkdir
        Quickshell.execDetached([safeCleanupScript, coverArt]);
        Quickshell.execDetached([safeCleanupScript, booruPreviews]);
        Quickshell.execDetached([safeCleanupScript, latexOutput]);
        Quickshell.execDetached([safeCleanupScript, cliphistDecode]);
    }
}
