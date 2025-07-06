import "root:/"
import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import QtQml
import Qt.labs.platform
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Button {
    id: root
    property var imageData
    property var rowHeight
    property bool manualDownload: false
    property string previewDownloadPath // e.g., Directories.booruPreviews
    property string downloadPath // e.g., Directories.booruDownloads
    property string nsfwPath // e.g., Directories.booruDownloadsNsfw
    property string sanitizedFileName: { // Moved from being fileName to sanitizedFileName
        let urlForFilename = imageData.file_url || imageData.preview_url || "unknown.jpg";
        let decodedName = decodeURIComponent(urlForFilename.substring(urlForFilename.lastIndexOf('/') + 1));
        let name = decodedName.replace(/[^a-zA-Z0-9._-]/g, "_").substring(0, 200);
        if (name === "" || name.startsWith(".")) name = `image_${Date.now()}.jpg`; // Ensure unique fallback
        return name;
    }
    property string filePath: `${root.previewDownloadPath}/${root.sanitizedFileName}` // Path for the preview
    property int maxTagStringLineLength: 50
    property real imageRadius: Appearance.rounding.small

    property bool showActions: false

    function getSafeUrl(url_string) {
        if (!url_string || typeof url_string !== 'string') return "";
        if (url_string.startsWith("https://")) {
            return url_string;
        } else if (url_string.startsWith("http://")) {
            // Log attempt to use HTTP, but allow for now. Could be made stricter.
            console.log(`[BooruImage] Warning: URL '${url_string}' is HTTP, not HTTPS.`);
            return url_string;
        }
        console.log(`[BooruImage] Error: Invalid URL scheme or non-string URL for '${url_string}'.`);
        return "";
    }

    Process {
        id: downloadPreviewProcess // Renamed from downloadProcess
        running: false
        // command will be set before running; not using bash -c
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // Check if file actually exists and is not empty, as curl might return 0 for some server errors (e.g. 404)
                // This would ideally use a FileInfo QML element or a script call.
                // For now, we assume success means the file is good.
                imageObject.source = "file:///" + root.filePath // Load from local file system
                console.log("[BooruImage] Preview loaded from local:", root.filePath);
            } else {
                console.log(`[BooruImage] Preview download failed for ${root.filePath} (URL: ${propertyCache.previewUrlToDownload}, Code: ${exitCode}, Status: ${exitStatus})`);
                // Optionally set a placeholder error image or leave the original network source
                imageObject.source = propertyCache.originalSourceUrl; // Fallback to network URL if download fails
            }
        }
    }

    // Cache properties that might change or are expensive to compute repeatedly
    QtObject {
        id: propertyCache
        property string previewUrlToDownload: getSafeUrl(root.imageData.preview_url ?? root.imageData.sample_url)
        property string originalSourceUrl: getSafeUrl(root.imageData.preview_url ?? root.imageData.sample_url) // Store original for fallback
    }

    Component.onCompleted: {
        // Set initial source for the image object
        imageObject.source = propertyCache.originalSourceUrl;

        if (root.manualDownload && propertyCache.previewUrlToDownload !== "") {
            // Ensure previewDownloadPath exists (should be done by Directories.qml on startup too)
            // Quickshell.execDetached(["mkdir", "-p", root.previewDownloadPath]); // Consider if needed repeatedly

            // TODO: Add a check here: if root.filePath already exists, don't re-download.
            // This requires a way to check file existence from QML, e.g. FileInfo or a script.
            // If (Quickshell.fileExists(root.filePath)) { imageObject.source = "file:///" + root.filePath; return; }

            console.log("[BooruImage] Attempting to download preview:", propertyCache.previewUrlToDownload, "to", root.filePath);
            downloadPreviewProcess.command = ["curl", "-sSL", "--connect-timeout", "10", "--max-time", "30", propertyCache.previewUrlToDownload, "-o", root.filePath];
            downloadPreviewProcess.running = true;
        } else if (propertyCache.previewUrlToDownload === "") {
            console.log("[BooruImage] No valid preview URL to download for:", root.sanitizedFileName);
        }
        // If not manualDownload, imageObject.source is already set to the network URL.
    }

    StyledToolTip {
        content: `${StringUtils.wordWrap(root.imageData.tags, root.maxTagStringLineLength)}`
    }

    padding: 0
    implicitWidth: root.rowHeight * modelData.aspect_ratio
    implicitHeight: root.rowHeight

    background: Rectangle {
        implicitWidth: root.rowHeight * modelData.aspect_ratio
        implicitHeight: root.rowHeight
        radius: imageRadius
        color: Appearance.colors.colLayer2
    }

    contentItem: Item {
        anchors.fill: parent

        Image {
            id: imageObject
            anchors.fill: parent
            width: root.rowHeight * modelData.aspect_ratio
            height: root.rowHeight
            visible: opacity > 0
            opacity: status === Image.Ready ? 1 : 0
            fillMode: Image.PreserveAspectFit
            source: modelData.preview_url
            sourceSize.width: root.rowHeight * modelData.aspect_ratio
            sourceSize.height: root.rowHeight

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: root.rowHeight * modelData.aspect_ratio
                    height: root.rowHeight
                    radius: imageRadius
                }
            }

            Behavior on opacity {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
            }
        }

        RippleButton {
            id: menuButton
            anchors.top: parent.top
            anchors.right: parent.right
            property real buttonSize: 30
            anchors.margins: Math.max(root.imageRadius - buttonSize / 2, 8)
            implicitHeight: buttonSize
            implicitWidth: buttonSize

            buttonRadius: Appearance.rounding.full
            colBackground: ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.3)
            colBackgroundHover: ColorUtils.transparentize(ColorUtils.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.8), 0.2)
            colRipple: ColorUtils.transparentize(ColorUtils.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.6), 0.1)

            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.m3colors.m3onSurface
                text: "more_vert"
            }

            onClicked: {
                root.showActions = !root.showActions
            }
        }

        Loader {
            id: contextMenuLoader
            active: root.showActions
            anchors.top: menuButton.bottom
            anchors.right: parent.right
            anchors.margins: 8

            sourceComponent: Item {
                width: contextMenu.width
                height: contextMenu.height

                StyledRectangularShadow {
                    target: contextMenu
                }
                Rectangle {
                    id: contextMenu
                    anchors.centerIn: parent
                    opacity: root.showActions ? 1 : 0
                    visible: opacity > 0
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colSurfaceContainer
                    implicitHeight: contextMenuColumnLayout.implicitHeight + radius * 2
                    implicitWidth: contextMenuColumnLayout.implicitWidth

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    ColumnLayout {
                        id: contextMenuColumnLayout
                        anchors.centerIn: parent
                        spacing: 0

                        MenuButton {
                            id: openFileLinkButton
                            Layout.fillWidth: true
                            buttonText: qsTr("Open file link")
                            onClicked: {
                                root.showActions = false
                                Hyprland.dispatch("keyword cursor:no_warps true")
                                Qt.openUrlExternally(root.imageData.file_url)
                                Hyprland.dispatch("keyword cursor:no_warps false")
                            }
                        }
                        MenuButton {
                            id: sourceButton
                            visible: root.imageData.source && root.imageData.source.length > 0
                            Layout.fillWidth: true
                            buttonText: StringUtils.format(qsTr("Go to source ({0})"), StringUtils.getDomain(root.imageData.source))
                            enabled: root.imageData.source && root.imageData.source.length > 0
                            onClicked: {
                                root.showActions = false
                                Hyprland.dispatch("keyword cursor:no_warps true")
                                Qt.openUrlExternally(root.imageData.source)
                                Hyprland.dispatch("keyword cursor:no_warps false")
                            }
                        }
                        MenuButton {
                            id: downloadButton
                            Layout.fillWidth: true
                            buttonText: qsTr("Download")
                            onClicked: {
                                root.showActions = false;
                                const fileUrl = getSafeUrl(root.imageData.file_url);
                                if (fileUrl === "") {
                                    console.log("[BooruImage] No valid full image URL for:", root.sanitizedFileName);
                                    Quickshell.execDetached(["notify-send", qsTr("Download Error"), qsTr("Invalid or missing URL for the image."), "-a", "Shell", "-u", "critical"]);
                                    return;
                                }

                                const targetDirectory = root.imageData.is_nsfw ? root.nsfwPath : root.downloadPath;
                                const fullDownloadPath = `${targetDirectory}/${root.sanitizedFileName}`;

                                // Ensure target directory exists
                                Quickshell.execDetached(["mkdir", "-p", targetDirectory]);

                                console.log(`[BooruImage] Downloading full image: ${fileUrl} to ${fullDownloadPath}`);
                                // Using array form for execDetached to avoid shell injection from fileUrl or fullDownloadPath
                                Quickshell.execDetached([
                                    "curl",
                                    "-L", // Follow redirects
                                    "--connect-timeout", "15", // Connection timeout
                                    "--max-time", "120",       // Max time for operation
                                    fileUrl,
                                    "-o", fullDownloadPath
                                    // Notification part removed from here.
                                    // Proper notification would require a dedicated Process element for this download
                                    // and handling onExited, or a helper script that downloads and then notifies.
                                ]);
                                // Simple notification that an attempt was made.
                                Quickshell.execDetached(["notify-send", qsTr("Download Started"), fileUrl, "-a", "Shell"]);
                            }
                        }
                    }
                }
            }
        }
    }
}