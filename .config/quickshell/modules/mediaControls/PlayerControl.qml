import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Item { // Player instance
    id: playerController
    required property MprisPlayer player
    // property var artUrl: player?.metadata["xesam:url"] || player?.metadata["mpris:artUrl"] || player?.trackArtUrl
    property var artUrl: player?.trackArtUrl
    property string localArt
    property color artDominantColor: "#00000000"

    implicitWidth: widgetWidth
    implicitHeight: widgetHeight

    onArtUrlChanged: {
        colorQuantizer.running = true
    }

    Process { // Average Color Runner
        id: colorQuantizer
        command: [ "sh", "-c", `magick ${playerController.player.trackArtUrl} -scale 1x1\\! -format '%[fx:int(255*r+.5)],%[fx:int(255*g+.5)],%[fx:int(255*b+.5)]' info: | sed 's/,/\\n/g' | xargs -L 1 printf '%02x' ; echo` ]
        stdout: SplitParser {
            onRead: data => {
                playerController.artDominantColor = "#" + data
            }
        }
    }

    property QtObject blendedColors: QtObject {
        property color colLayer0: Appearance.mix(Appearance.colors.colLayer0, artDominantColor, 0.7)
        property color colLayer1: Appearance.mix(Appearance.colors.colLayer1, artDominantColor, 0.5)
        property color colOnLayer0: Appearance.mix(Appearance.colors.colOnLayer0, artDominantColor, 0.7)
        property color colOnLayer1: Appearance.mix(Appearance.colors.colOnLayer1, artDominantColor, 0.5)
        property color colSubtext: Appearance.mix(Appearance.colors.colSubtext, artDominantColor, 0.5)
        property color colPrimary: Appearance.mix(Appearance.m3colors.m3primary, artDominantColor, 0.3)
        property color colPrimaryHover: Appearance.mix(Appearance.colors.colPrimaryHover, artDominantColor, 0.3)
        property color colPrimaryActive: Appearance.mix(Appearance.colors.colPrimaryActive, artDominantColor, 0.3)
        property color colSecondaryContainer: Appearance.mix(Appearance.m3colors.m3secondaryContainer, artDominantColor, 0.5)
        property color colSecondaryContainerHover: Appearance.mix(Appearance.colors.colSecondaryContainerHover, artDominantColor, 0.3)
        property color colSecondaryContainerActive: Appearance.mix(Appearance.colors.colSecondaryContainerActive, artDominantColor, 0.3)
        property color colOnPrimary: Appearance.mix(Appearance.colors.colOnPrimary, artDominantColor, 0.5)
        property color colOnSecondaryContainer: Appearance.mix(Appearance.m3colors.m3onSecondaryContainer, artDominantColor, 0.2)

    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: blendedColors.colLayer0
        radius: root.popupRounding

        RowLayout {
            anchors.fill: parent
            anchors.margins: root.contentPadding
            spacing: 15

            Rectangle { // Art backgrounmd
                Layout.fillHeight: true
                implicitWidth: height
                radius: root.artRounding
                color: blendedColors.colLayer1

                Image { // Art image
                    id: mediaArt
                    property int size: parent.height
                    anchors.fill: parent

                    source: playerController.artUrl
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    antialiasing: true
                    asynchronous: true

                    width: size
                    height: size
                    sourceSize.width: size
                    sourceSize.height: size

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: mediaArt.size
                            height: mediaArt.size
                            radius: root.artRounding
                        }
                    }
                }
            }

            ColumnLayout { // Info & controls
                Layout.fillHeight: true
                spacing: 2

                StyledText {
                    id: trackTitle
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: blendedColors.colOnLayer0
                    elide: Text.ElideRight
                    text: StringUtils.cleanMusicTitle(playerController.player?.trackTitle) || "Untitled"
                }
                StyledText {
                    id: trackArtist
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: blendedColors.colSubtext
                    elide: Text.ElideRight
                    text: playerController.player?.trackArtist
                }
                Item { Layout.fillHeight: true }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: trackTime.implicitHeight + slider.implicitHeight

                    StyledText {
                        id: trackTime
                        anchors.bottom: slider.top
                        anchors.bottomMargin: -4
                        anchors.left: parent.left
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: blendedColors.colSubtext
                        elide: Text.ElideRight
                        text: `${StringUtils.friendlyTimeForSeconds(playerController.player?.position)} / ${StringUtils.friendlyTimeForSeconds(playerController.player?.length)}`
                    }
                    StyledSlider {
                        id: slider
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                            bottomMargin: -8
                        }
                        highlightColor: blendedColors.colPrimary
                        trackColor: blendedColors.colSecondaryContainer
                        handleColor: blendedColors.colOnSecondaryContainer
                        scale: 0.6
                        value: playerController.player?.position / playerController.player?.length
                        onMoved: playerController.player.position = value * playerController.player.length
                        tooltipContent: StringUtils.friendlyTimeForSeconds(playerController.player?.position)
                    }

                    Button {
                        id: playPauseButton
                        anchors.right: parent.right
                        anchors.bottom: slider.top
                        anchors.bottomMargin: -1
                        implicitWidth: 44
                        implicitHeight: 44
                        onClicked: playerController.player.togglePlaying();

                        PointingHandInteraction {}

                        background: Rectangle {
                            color: playerController.player?.isPlaying ? 
                                (playPauseButton.pressed ? blendedColors.colPrimaryActive : 
                                    playPauseButton.hovered ? blendedColors.colPrimaryHover : 
                                    blendedColors.colPrimary) : 
                                (playPauseButton.pressed ? blendedColors.colSecondaryContainerActive : 
                                    playPauseButton.hovered ? blendedColors.colSecondaryContainerHover : 
                                    blendedColors.colSecondaryContainer)
                            radius: Appearance.rounding.full

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }

                        contentItem: MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.huge
                            fill: 1
                            horizontalAlignment: Text.AlignHCenter
                            color: playerController.player?.isPlaying ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSecondaryContainer
                            text: playerController.player?.isPlaying ? "pause" : "play_arrow"

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }
                    }
                }
            }
        }
    }

    DropShadow {
        anchors.fill: background
        source: background
        horizontalOffset: 0
        verticalOffset: 2
        radius: Appearance.sizes.elevationMargin
        samples: Appearance.sizes.elevationMargin * 2 + 1 // Ideally should be 2 * radius + 1, see qt docs
        color: Appearance.colors.colShadow
    }
}