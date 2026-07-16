import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.common.widgets
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Button {
    id: root
    property var imageData
    property var rowHeight
    property bool manualDownload: false
    property string previewDownloadPath
    property string downloadPath
    property string nsfwPath
    property string refererUrl: ""
    property string defaultUserAgent: Config.options?.networking?.userAgent
        ?? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    property string fileName: decodeURIComponent((imageData.file_url).substring((imageData.file_url).lastIndexOf('/') + 1))
    property string filePath: `${root.previewDownloadPath}/${root.fileName}`
    property int maxTagStringLineLength: 50
    property real imageRadius: Appearance.rounding.small

    property bool showActions: false

    // Standard downloader — used for all providers WITHOUT hotlink protection
    ImageDownloaderProcess {
        id: imageDownloader
        running: root.refererUrl === ""
        filePath: root.filePath
        sourceUrl: root.imageData.sample_url ?? root.imageData.preview_url ?? root.imageData.file_url
        onDone: (path, width, height) => {
            imageObject.source = path
            if (!modelData.width || !modelData.height) {
                modelData.width = width
                modelData.height = height
                modelData.aspect_ratio = width / height
            }
        }
    }

    // Referer-aware downloader via curl — used for providers with hotlink protection (e.g. Gelbooru)
    Process {
        id: refererDownloader
        running: root.refererUrl !== ""
        command: ["bash", "-c",
            `mkdir -p '${StringUtils.shellSingleQuoteEscape(root.previewDownloadPath)}' && ` +
            `[ -f '${StringUtils.shellSingleQuoteEscape(root.filePath)}' ] || ` +
            `(curl -s -L ` +
            `-H 'Referer: ${root.refererUrl}' ` +
            `-H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(root.defaultUserAgent)}' ` +
            `'${StringUtils.shellSingleQuoteEscape(root.imageData.sample_url ?? root.imageData.file_url)}' ` +
            `-o '${StringUtils.shellSingleQuoteEscape(root.filePath)}' ` +
            `|| curl -s -L ` +
            `-H 'Referer: ${root.refererUrl}' ` +
            `-H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(root.defaultUserAgent)}' ` +
            `'${StringUtils.shellSingleQuoteEscape(root.imageData.preview_url)}' ` +
            `-o '${StringUtils.shellSingleQuoteEscape(root.filePath)}') && echo DONE`
        ]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() === "DONE") {
                    imageObject.source = root.filePath
                }
            }
        }
    }

    StyledToolTip {
        text: `${StringUtils.wordWrap(root.imageData.tags, root.maxTagStringLineLength)}`
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

        StyledImage {
            id: imageObject
            anchors.fill: parent
            width: root.rowHeight * modelData.aspect_ratio
            height: root.rowHeight
            fillMode: Image.PreserveAspectFit
            source: root.refererUrl !== "" ? "" : modelData.preview_url

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: root.rowHeight * modelData.aspect_ratio
                    height: root.rowHeight
                    radius: imageRadius
                }
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
                    color: Appearance.m3colors.m3surfaceContainer
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
                            buttonText: Translation.tr("Open file link")
                            onClicked: {
                                root.showActions = false
                                Hyprland.dispatch("hl.config({cursor = {no_warps = true}})")
                                Qt.openUrlExternally(root.imageData.file_url)
                                Hyprland.dispatch("hl.config({cursor = {no_warps = false}})")
                            }
                        }
                        MenuButton {
                            id: sourceButton
                            visible: root.imageData.source && root.imageData.source.length > 0
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Go to source (%1)").arg(StringUtils.getDomain(root.imageData.source))
                            enabled: root.imageData.source && root.imageData.source.length > 0
                            onClicked: {
                                root.showActions = false
                                Hyprland.dispatch("hl.config({cursor = {no_warps = true}})")
                                Qt.openUrlExternally(root.imageData.source)
                                Hyprland.dispatch("hl.config({cursor = {no_warps = false}})")
                            }
                        }
                        MenuButton {
                            id: downloadButton
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Download")
                            onClicked: {
                                root.showActions = false;
                                const targetPath = root.imageData.is_nsfw ? root.nsfwPath : root.downloadPath;
                                const userAgent = Config.options?.networking?.userAgent ?? ""
                                const userAgentHeader = userAgent ? ` -H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(userAgent)}'` : ""
                                const refererHeader = root.refererUrl ? ` -H 'Referer: ${root.refererUrl}'` : ""
                                Quickshell.execDetached(["bash", "-c", 
                                    `mkdir -p '${targetPath}' && curl '${StringUtils.shellSingleQuoteEscape(root.imageData.file_url)}'${userAgentHeader}${refererHeader} -o '${targetPath}/${root.fileName}' && notify-send '${Translation.tr("Download complete")}' '${root.downloadPath}/${root.fileName}' -a 'Shell'`
                                ])
                            }
                        }
                    }
                }
            }
        }
    }
}
