import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// From https://github.com/caelestia-dots/shell with modifications.
// License: GPLv3

Image {
    id: root
    required property var fileModelData
    asynchronous: true
    fillMode: Image.PreserveAspectFit

    source: {
        if (!fileModelData.fileIsDir)
            return Quickshell.iconPath("application-x-zerosize");

        const name = fileModelData.fileName;
        const homeDir = Directories.home
        if ([Directories.documents, Directories.downloads, Directories.music, Directories.pictures, Directories.videos].includes(name))
            return Quickshell.iconPath(`folder-${name.toLowerCase()}`);

        return Quickshell.iconPath("inode-directory");
    }

    onStatusChanged: {
        if (status === Image.Error)
            source = Quickshell.iconPath("error");
    }

    Process {
        running: !fileModelData.fileIsDir
        command: ["file", "--mime", "-b", fileModelData.filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const mime = text.split(";")[0].replace("/", "-");
                root.source = Images.validImageTypes.some(t => mime === `image-${t}`) ? fileModelData.fileUrl : Quickshell.iconPath(mime, "image-missing");
            }
        }
    }
}
