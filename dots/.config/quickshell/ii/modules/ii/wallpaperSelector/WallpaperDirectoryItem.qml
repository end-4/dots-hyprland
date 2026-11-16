import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    required property var fileModelData
    property bool isDirectory: fileModelData.fileIsDir
    property bool isVideo: Images.isValidVideoByName(fileModelData.fileName)
    property bool useThumbnail: Images.isValidImageByName(fileModelData.fileName) || isVideo

    property bool isDarkWallpaper: !isDirectory && fileModelData.filePath === Config.options.background.darkWallpaperPath
    property bool isLightWallpaper: !isDirectory && fileModelData.filePath === Config.options.background.lightWallpaperPath

    property alias colBackground: background.color
    property alias colText: wallpaperItemName.color
    property alias radius: background.radius
    property alias margins: background.anchors.margins
    property alias padding: wallpaperItemColumnLayout.anchors.margins
    margins: Appearance.sizes.wallpaperSelectorItemMargins
    padding: Appearance.sizes.wallpaperSelectorItemPadding

    signal activated()
    signal rightClicked()

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            root.rightClicked();
        } else {
            root.activated();
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Appearance.rounding.normal
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: wallpaperItemColumnLayout
            anchors.fill: parent
            spacing: 4

            Item {
                id: wallpaperItemImageContainer
                Layout.fillHeight: true
                Layout.fillWidth: true

                Loader {
                    id: thumbnailShadowLoader
                    active: thumbnailImageLoader.active && thumbnailImageLoader.item.status === Image.Ready
                    anchors.fill: thumbnailImageLoader
                    sourceComponent: StyledRectangularShadow {
                        target: thumbnailImageLoader
                        anchors.fill: undefined
                        radius: Appearance.rounding.small
                    }
                }

                Loader {
                    id: thumbnailImageLoader
                    anchors.fill: parent
                    active: root.useThumbnail
                    sourceComponent: ThumbnailImage {
                        id: thumbnailImage
                        generateThumbnail: false
                        sourcePath: fileModelData.filePath

                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        clip: true

                        Connections {
                            target: Wallpapers
                            function onThumbnailGenerated(directory) {
                                if (thumbnailImage.status !== Image.Error) return;
                                if (FileUtils.parentDirectory(thumbnailImage.sourcePath) !== FileUtils.trimFileProtocol(directory)) return;
                                thumbnailImage.source = "";
                                thumbnailImage.source = thumbnailImage.thumbnailPath;
                            }
                            function onThumbnailGeneratedFile(filePath) {
                                if (thumbnailImage.status !== Image.Error) return;
                                if (Qt.resolvedUrl(thumbnailImage.sourcePath) !== Qt.resolvedUrl(filePath)) return;
                                thumbnailImage.source = "";
                                thumbnailImage.source = thumbnailImage.thumbnailPath;
                            }
                        }

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: wallpaperItemImageContainer.width
                                height: wallpaperItemImageContainer.height
                                radius: Appearance.rounding.small
                            }
                        }
                    }
                }

                Loader {
                    id: iconLoader
                    active: !root.useThumbnail
                    anchors.fill: parent
                    sourceComponent: DirectoryIcon {
                        fileModelData: root.fileModelData
                    }
                }

                Rectangle {
                    visible: root.isVideo
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 6
                    }
                    width: 22
                    height: 22
                    radius: Appearance.rounding.small
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.25)
                    border.color: Appearance.colors.colOutlineVariant
                    border.width: 1
                    z: 10

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "movie"
                        iconSize: 14
                        color: Appearance.colors.colPrimary
                    }
                }

                // Badges for Dual Wallpaper status
                Row {
                    anchors {
                        top: parent.top
                        left: parent.left
                        margins: 6
                    }
                    spacing: 4
                    z: 10

                    Rectangle {
                        visible: root.isDarkWallpaper
                        width: 22
                        height: 22
                        radius: Appearance.rounding.small
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.2)
                        border.color: Appearance.colors.colSecondary
                        border.width: 1.5

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "dark_mode"
                            iconSize: 13
                            color: Appearance.colors.colSecondary
                        }
                    }

                    Rectangle {
                        visible: root.isLightWallpaper
                        width: 22
                        height: 22
                        radius: Appearance.rounding.small
                        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.2)
                        border.color: Appearance.colors.colTertiary
                        border.width: 1.5

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "light_mode"
                            iconSize: 13
                            color: Appearance.colors.colTertiary
                        }
                    }
                }
            }

            StyledText {
                id: wallpaperItemName
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10

                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                text: fileModelData.fileName
            }
        }
    }
}
