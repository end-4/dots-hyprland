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
    property color artDominantColor: Appearance.m3colors.m3primaryFixed

    implicitWidth: widgetWidth
    implicitHeight: widgetHeight

    component TrackChangeButton: Button {
        id: playPauseButton
        implicitWidth: 24
        implicitHeight: 24

        property var iconName
        PointingHandInteraction {}

        background: Rectangle {
            color: playPauseButton.pressed ? blendedColors.colSecondaryContainerActive : 
                playPauseButton.hovered ? blendedColors.colSecondaryContainerHover : 
                Appearance.transparentize(blendedColors.colSecondaryContainer, 1)
            radius: Appearance.rounding.full

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

        contentItem: MaterialSymbol {
            iconSize: Appearance.font.pixelSize.huge
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    Timer { // Force update for prevision
        running: playerController.player?.playbackState == MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: {
            playerController.player.positionChanged()
        }
    }

    onArtUrlChanged: {
        if (playerController.artUrl.length == 0) return;
        colorQuantizer.targetFile = playerController.artUrl // Yes this binding break is intentional
        colorQuantizer.running = true
    }

    Process { // Average Color Runner
        id: colorQuantizer
        property string targetFile: playerController.artUrl
        command: [ "sh", "-c", `magick '${targetFile}' -scale 1x1\\! -format '%[fx:int(255*r+.5)],%[fx:int(255*g+.5)],%[fx:int(255*b+.5)]' info: | sed 's/,/\\n/g' | xargs -L 1 printf '%02x' ; echo` ]
        stdout: SplitParser {
            onRead: data => {
                // console.log("Color quantizer output:", data)
                playerController.artDominantColor = "#" + data
            }
        }
    }

    property QtObject blendedColors: QtObject {
        property color colLayer0: Appearance.mix(Appearance.colors.colLayer0, artDominantColor, 0.6)
        property color colLayer1: Appearance.mix(Appearance.colors.colLayer1, artDominantColor, 0.5)
        property color colOnLayer0: Appearance.mix(Appearance.colors.colOnLayer0, artDominantColor, 0.7)
        property color colOnLayer1: Appearance.mix(Appearance.colors.colOnLayer1, artDominantColor, 0.5)
        property color colSubtext: Appearance.mix(Appearance.colors.colSubtext, artDominantColor, 0.5)
        property color colPrimary: Appearance.mix(Appearance.colorWithHueOf(Appearance.m3colors.m3primary, artDominantColor), artDominantColor, 0.5)
        property color colPrimaryHover: Appearance.mix(Appearance.colorWithHueOf(Appearance.colors.colPrimaryHover, artDominantColor), artDominantColor, 0.3)
        property color colPrimaryActive: Appearance.mix(Appearance.colorWithHueOf(Appearance.colors.colPrimaryActive, artDominantColor), artDominantColor, 0.3)
        property color colSecondaryContainer: Appearance.mix(Appearance.m3colors.m3secondaryContainer, artDominantColor, 0.3)
        property color colSecondaryContainerHover: Appearance.mix(Appearance.colors.colSecondaryContainerHover, artDominantColor, 0.3)
        property color colSecondaryContainerActive: Appearance.mix(Appearance.colors.colSecondaryContainerActive, artDominantColor, 0.3)
        property color colOnPrimary: Appearance.mix(Appearance.colorWithHueOf(Appearance.m3colors.m3onPrimary, artDominantColor), artDominantColor, 0.5)
        property color colOnSecondaryContainer: Appearance.mix(Appearance.m3colors.m3onSecondaryContainer, artDominantColor, 0.2)

    }

    Rectangle {
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: blendedColors.colLayer0
        radius: root.popupRounding

        LinearGradient {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: background.width
                    height: background.height
                    radius: root.popupRounding
                }
            }
            start: Qt.point(0, 0)
            end: Qt.point(background.width, background.height)
            gradient: Gradient {
                GradientStop { position: 0.0; color: Appearance.transparentize(artDominantColor, 0.6) }
                GradientStop { position: 0.4; color: Appearance.transparentize(artDominantColor, 0.8) }
            }
        }

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
                    implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight

                    StyledText {
                        id: trackTime
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
                        anchors.left: parent.left
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: blendedColors.colSubtext
                        elide: Text.ElideRight
                        text: `${StringUtils.friendlyTimeForSeconds(playerController.player?.position)} / ${StringUtils.friendlyTimeForSeconds(playerController.player?.length)}`
                    }
                    RowLayout {
                        id: sliderRow
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                            bottomMargin: 5
                        }
                        TrackChangeButton {
                            iconName: "skip_previous"
                            onClicked: playerController.player?.previous()
                        }
                        StyledProgressBar {
                            id: slider
                            Layout.fillWidth: true
                            highlightColor: blendedColors.colPrimary
                            trackColor: blendedColors.colSecondaryContainer
                            value: playerController.player?.position / playerController.player?.length
                        }
                        TrackChangeButton {
                            iconName: "skip_next"
                            onClicked: playerController.player?.next()
                        }
                    }

                    Button {
                        id: playPauseButton
                        anchors.right: parent.right
                        anchors.bottom: sliderRow.top
                        anchors.bottomMargin: 5
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
                            color: playerController.player?.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
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