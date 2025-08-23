import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property string path
    property bool isHovered: false

    property alias color: background.color
    property alias radius: background.radius
    property alias padding: background.anchors.margins

    signal activated()

    Rectangle {
        id: background
        anchors {
            fill: parent
            margins: 8
        }
        radius: Appearance.rounding.normal
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: wallpaperItemColumnLayout
            anchors {
                fill: parent
                margins: 6
            }
            spacing: 4

            Item {
                id: wallpaperItemImageContainer
                Layout.fillHeight: true
                Layout.fillWidth: true

                StyledRectangularShadow {
                    target: thumbnailImageLoader
                    radius: Appearance.rounding.small
                }

                Loader {
                    id: thumbnailImageLoader
                    anchors.fill: parent
                    active: root.visible
                    sourceComponent: Image {
                        id: thumbnailImage
                        source: {
                            if (root.path.length == 0)
                                return;
                            const resolvedUrl = Qt.resolvedUrl(root.path);
                            const md5Hash = Qt.md5(resolvedUrl);
                            const cacheSize = "normal";
                            const thumbnailPath = `${Directories.genericCache}/thumbnails/${cacheSize}/${md5Hash}.png`;
                            return thumbnailPath;
                        }
                        asynchronous: true
                        cache: false
                        smooth: true
                        mipmap: false

                        fillMode: Image.PreserveAspectCrop
                        clip: true
                        sourceSize.width: wallpaperItemColumnLayout.width
                        sourceSize.height: wallpaperItemColumnLayout.height - wallpaperItemColumnLayout.spacing - wallpaperItemName.height

                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
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
            }

            StyledText {
                id: wallpaperItemName
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10

                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: (index === grid.currentIndex || parent.isHovered) ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                text: FileUtils.fileNameForPath(root.path)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            for (let i = 0; i < grid.count; i++) {
                const item = grid.itemAtIndex(i);
                if (item && item !== parent) {
                    item.isHovered = false;
                }
            }
            parent.isHovered = true;
            grid.currentIndex = index;
        }
        onExited: {
            parent.isHovered = false;
        }
        onClicked: root.activated()
    }
}