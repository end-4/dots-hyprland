pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    showClickabilityButton: false
    resizable: false
    clickthrough: true

    property string imageSource: Config.options.overlay.floatingImage.imageSource
    property real scaleFactor: Config.options.overlay.floatingImage.scale
    property int imageWidth: 0
    property int imageHeight: 0

    // Override to always save 0 size
    function savePosition(xPos = root.x, yPos = root.y, width = 0, height = 0) {
        root.persistentStateEntry.x = Math.round(xPos);
        root.persistentStateEntry.y = Math.round(yPos);
        root.persistentStateEntry.width = 0
        root.persistentStateEntry.height = 0
    }

    onImageSourceChanged: {
        imageDownloader.running = false;
        imageDownloader.sourceUrl = root.imageSource;
        imageDownloader.filePath = Qt.resolvedUrl(Directories.tempImages + "/" + Qt.md5(root.imageSource))
        imageDownloader.running = true;
    }
    onScaleFactorChanged: {
        setSize();
    }

    function setSize() {
        bg.implicitWidth = root.imageWidth * root.scaleFactor;
        bg.implicitHeight = root.imageHeight * root.scaleFactor;
    }

    contentItem: OverlayBackground {
        id: bg
        color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, root.actuallyPinned ? 1 : 0)
        radius: root.contentRadius

        WheelHandler {
            onWheel: (event) => {
                if (event.angleDelta.y < 0) {
                    Config.options.overlay.floatingImage.scale = Math.max(0.1, Config.options.overlay.floatingImage.scale - 0.1);
                }
                else if (event.angleDelta.y > 0) {
                    Config.options.overlay.floatingImage.scale = Math.min(5.0, Config.options.overlay.floatingImage.scale + 0.1);
                }
            }
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: bg.width
                height: bg.height
                radius: bg.radius
            }
        }

        AnimatedImage {
            id: animatedImage
            anchors.centerIn: parent
            width: root.imageWidth * root.scaleFactor
            height: root.imageHeight * root.scaleFactor
            sourceSize.width: width
            sourceSize.height: height

            playing: visible
            asynchronous: true
            source: ""

            ImageDownloaderProcess {
                id: imageDownloader
                filePath: Qt.resolvedUrl(Directories.tempImages + "/" + Qt.md5(root.imageSource))
                sourceUrl: root.imageSource

                onDone: (path, width, height) => {
                    root.imageWidth = width;
                    root.imageHeight = height;
                    root.setSize();
                    animatedImage.source = path;
                }
            }
        }
    }
}
