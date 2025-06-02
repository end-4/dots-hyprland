pragma Singleton

import "root:/modules/common/functions/file_utils.js" as FileUtils
import "root:/modules/common"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root
    property string firstRunFilePath: `${Directories.state}/user/first_run.txt`
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property string firstRunNotifSummary: "Welcome!"
    property string firstRunNotifBody: "Hit Super+/ for a list of keybinds"
    property string defaultWallpaperPath: FileUtils.trimFileProtocol(`${Directories.config}/quickshell/assets/images/default_wallpaper.png`)

    function load() {
        firstRunFileView.reload()
    }

    function handleFirstRun() {
        Hyprland.dispatch(`exec notify-send '${root.firstRunNotifSummary}' '${root.firstRunNotifBody}' -a 'Shell'`)
        Hyprland.dispatch(`exec '${Directories.wallpaperSwitchScriptPath}' '${root.defaultWallpaperPath}'`)
    }

    FileView {
        id: firstRunFileView
        path: Qt.resolvedUrl(firstRunFilePath)
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                firstRunFileView.setText(root.firstRunFileContent)
                root.handleFirstRun()
            }
        }
    }
}
