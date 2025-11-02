import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import QtQuick.Effects

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("")

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            }
        }
    }

    RowLayout { // Real content
        id: rowLayout

        spacing: 4
        anchors.fill: parent

        Image { // Art image
            Layout.alignment: Qt.AlignVCenter
            source: activePlayer?.trackArtUrl && activePlayer.trackArtUrl !== "" ? activePlayer.trackArtUrl : "../../assets/icons/cover.png"
            fillMode: Image.PreserveAspectCrop
            cache: false
            width: 25
            height: 25
            sourceSize.width: 25
            sourceSize.height: 25

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: 25
                    height: 25
                    radius: 6
                }
            }
        }

        Column {
            visible: Config.options.bar.verbose
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: -4
            
            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                color: Appearance.colors.colSubtext
                text: activePlayer?.trackArtist || " "
                font.pixelSize: 12
            }
            
            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                color: Appearance.colors.colOnLayer1
                text: cleanedTitle
                font.weight: Font.Medium
                font.pixelSize: 13
            }
        }
        
        ClippedFilledCircularProgress {
            id: mediaCircProg
            visible: Config.options.bar.verbose
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: activePlayer?.position / activePlayer?.length
            implicitSize: 20
            colPrimary: Appearance.colors.colOnSecondaryContainer
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }
    }
}
