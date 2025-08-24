import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

/**
 * Thumbnail image.
 * See Freedesktop's spec: https://specifications.freedesktop.org/thumbnail-spec/thumbnail-spec-latest.html
 */
Image {
    id: root

    required property string sourcePath
    readonly property var thumbnailSizes: ({
        "normal": 128,
        "large": 256,
        "x-large": 512,
        "xx-large": 1024
    })
    property string thumbnailSizeName: { // https://specifications.freedesktop.org/thumbnail-spec/latest/directory.html
        const sizeNames = Object.keys(thumbnailSizes);
        for(let i = 0; i < sizeNames.length; i++) {
            const sizeName = sizeNames[i];
            const maxSize = thumbnailSizes[sizeName];
            if (root.sourceSize.width <= maxSize && root.sourceSize.height <= maxSize) return sizeName;
        }
        return "xx-large";
    }
    property string thumbnailPath: {
        if (sourcePath.length == 0) return;
        const resolvedUrl = Qt.resolvedUrl(sourcePath);
        const md5Hash = Qt.md5(resolvedUrl);
        return `${Directories.genericCache}/thumbnails/${thumbnailSizeName}/${md5Hash}.png`;
    }
    source: thumbnailPath

    asynchronous: true
    cache: false
    smooth: true
    mipmap: false

    opacity: status === Image.Ready ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    onSourceSizeChanged: {
        thumbnailGeneration.running = false
        thumbnailGeneration.running = true
    }
    Process {
        id: thumbnailGeneration
        command: {
            const maxSize = root.thumbnailSizes[root.thumbnailSizeName];
            return ["bash", "-c", 
                `[ -f '${FileUtils.trimFileProtocol(root.thumbnailPath)}' ] && exit 0 || { magick '${root.sourcePath}' -resize ${maxSize}x${maxSize} '${FileUtils.trimFileProtocol(root.thumbnailPath)}' && exit 1; }`
            ]
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) { // Force reload if thumbnail had to be generated
                root.source = "";
                root.source = root.thumbnailPath; // Force reload
            }
        }
    }
}
