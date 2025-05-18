import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils
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

Scope {
    id: root
    required property var bar
    property bool visible: false
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property real osdWidth: Appearance.sizes.osdWidth
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight
    property real contentPadding: 12
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.elevationMargin + 1
    property real artRounding: Appearance.rounding.verysmall
    property string baseCoverArtDir: FileUtils.trimFileProtocol(`${XdgDirectories.cache}/media/coverart`)

    Component.onCompleted: {
        Hyprland.dispatch(`exec rm -rf ${baseCoverArtDir} && mkdir -p ${baseCoverArtDir}`)
    }

    Loader {
        id: mediaControlsLoader
        active: false

        PanelWindow {
            id: mediaControlsRoot
            visible: mediaControlsLoader.active

            exclusiveZone: 0
            implicitWidth: (
                (mediaControlsRoot.screen.width / 2) // Middle of screen
                    - (osdWidth / 2)                 // Dodge OSD
                    - (widgetWidth / 2)              // Account for widget width
            ) * 2
            implicitHeight: playerColumnLayout.implicitHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:mediaControls"

            anchors {
                top: true
                left: true
            }

            ColumnLayout {
                id: playerColumnLayout
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                x: (mediaControlsRoot.screen.width / 2)  // Middle of screen
                    - (osdWidth / 2)                     // Dodge OSD
                    - (widgetWidth)                      // Account for widget width
                    + (Appearance.sizes.elevationMargin) // It's fine for shadows to overlap

                Item { // Player instance
                    id: playerController
                    property MprisPlayer player: root.activePlayer

                    implicitWidth: widgetWidth
                    implicitHeight: widgetHeight
                    property string fileName: Qt.md5(activePlayer?.trackArtUrl) + ".jpg"
                    property string filePath: `${root.baseCoverArtDir}/${fileName}`

                    Process {
                        id: downloadProcess
                        running: false
                        command: ["bash", "-c", `[ -f ${playerController.filePath} ] || curl '${playerController.player?.trackArtUrl}' -o '${playerController.filePath}'`]
                        onExited: (exitCode, exitStatus) => {
                            colorQuantizer.source = playerController.filePath
                        }
                    }

                    ColorQuantizer {
                        id: colorQuantizer
                        depth: 1 // 2^1 colors
                        rescaleSize: 64 // Rescale to 64x64 for faster processing
                    }

                    property QtObject blendedColors: QtObject {
                        // property color colLayer0: Appearance.mix(Appearance.colors.colLayer0, colorQuantizer.colors[0], 0.5)
                    }

                    Rectangle {
                        id: background
                        anchors.fill: parent
                        anchors.margins: Appearance.sizes.elevationMargin
                        color: Appearance.colors.colLayer0
                        radius: root.popupRounding

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: root.contentPadding
                            spacing: 10

                            Rectangle { // Art backgrounmd
                                Layout.fillHeight: true
                                implicitWidth: height
                                radius: root.artRounding
                                color: Appearance.colors.colLayer1

                                Image { // Art image
                                    id: mediaArt
                                    property int size: parent.height
                                    anchors.fill: parent

                                    source: playerController.player?.trackArtUrl
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
                                    color: Appearance.colors.colOnLayer0
                                    elide: Text.ElideRight
                                    text: StringUtils.cleanMusicTitle(playerController.player?.trackTitle) || "No media"
                                }
                                StyledText {
                                    id: trackArtist
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
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
                                        color: Appearance.colors.colSubtext
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
                                        scale: 0.7
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
                                                (playPauseButton.pressed ? Appearance.colors.colPrimaryActive : 
                                                    playPauseButton.hovered ? Appearance.colors.colPrimaryHover : 
                                                    Appearance.m3colors.m3primary) : 
                                                (playPauseButton.pressed ? Appearance.colors.colSecondaryContainerActive : 
                                                    playPauseButton.hovered ? Appearance.colors.colSecondaryContainerHover : 
                                                    Appearance.m3colors.m3secondaryContainer)
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
            }
        }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            mediaControlsLoader.active = !mediaControlsLoader.active;
            if(mediaControlsLoader.active) Notifications.timeoutAll();
        }

        function close(): void {
            mediaControlsLoader.active = false;
        }

        function open(): void {
            mediaControlsLoader.active = true;
            Notifications.timeoutAll();
        }
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Toggles media controls on press"

        onPressed: {
            mediaControlsLoader.active = !mediaControlsLoader.active;
            if(mediaControlsLoader.active) Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "mediaControlsOpen"
        description: "Opens media controls on press"

        onPressed: {
            mediaControlsLoader.active = true;
            Notifications.timeoutAll();
        }
    }
    GlobalShortcut {
        name: "mediaControlsClose"
        description: "Closes media controls on press"

        onPressed: {
            mediaControlsLoader.active = false;
        }
    }

}