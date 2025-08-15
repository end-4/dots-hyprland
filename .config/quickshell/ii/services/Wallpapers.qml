import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property var wallpaperList: []
    property var thumbnailsList: []

    Process {
        id: listWallpapers
        running: true
        command: [
            "bash", "-c",
            "find " + Directories.wallpaperPath + " -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%f\\n'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wallpaperList = text.split('\n').filter(function(item) { return item.length > 0; });
            }
        }
    }

    Process {
        id: listThumbnails
        running: true
        command: [
            "bash", "-c",
            "find " + `${Directories.wallpaperPath}/thumbnails` + " -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%f\\n'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.thumbnailsList = text.split('\n').filter(function(item) { return item.length > 0; });
            }
        }
    }


}