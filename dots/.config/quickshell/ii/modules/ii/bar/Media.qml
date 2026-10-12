import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    readonly property bool showLyrics: LyricsService.lyricsEnabled && LyricsService.hasTrack

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        // Lyrics need a finer position signal than the resource widgets do
        interval: root.showLyrics ? 250 : Config.options.resources.updateInterval
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

        ClippedFilledCircularProgress {
            id: mediaCircProg
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

        Item { // Track title, or the lyrics when they're enabled
            visible: Config.options.bar.verbose
            Layout.fillWidth: true // Ensures the text takes up available space
            Layout.fillHeight: true
            Layout.rightMargin: rowLayout.spacing
            clip: true

            StyledText {
                anchors.fill: parent
                visible: !root.showLyrics
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight // Truncates the text on the right
                color: Appearance.colors.colOnLayer1
                text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
            }

            Item {
                id: lyricScroller
                anchors.fill: parent
                visible: root.showLyrics

                readonly property int rowHeight: Math.max(10, Math.min(Math.floor(height / 3), Appearance.font.pixelSize.smallie))
                // Previous, current and next line. Without timestamps to sync to,
                // the middle row carries the status text instead.
                readonly property var texts: LyricsService.lines.length > 0 ? [LyricsService.prevLineText, LyricsService.currentLineText || "♪", LyricsService.nextLineText] : ["", LyricsService.displayText, ""]

                readonly property real dimOpacity: 0.6
                readonly property real dimScale: Appearance.font.pixelSize.smaller / Appearance.font.pixelSize.smallie

                // Rows slide in from whichever side the song moved towards, so
                // scrollOffset starts one row out and animates back to centre.
                property real scrollOffset: 0
                property bool movingForward: true
                readonly property real progress: Math.abs(scrollOffset) / rowHeight

                readonly property int lineIndex: LyricsService.currentIndex
                property int lastIndex: -1
                onLineIndexChanged: {
                    movingForward = lineIndex > lastIndex;
                    lastIndex = lineIndex;
                    scrollAnimation.restart();
                }

                SequentialAnimation {
                    id: scrollAnimation
                    PropertyAction {
                        target: lyricScroller
                        property: "scrollOffset"
                        value: lyricScroller.movingForward ? -lyricScroller.rowHeight : lyricScroller.rowHeight
                    }
                    NumberAnimation {
                        target: lyricScroller
                        property: "scrollOffset"
                        to: 0
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    y: Math.max(0, Math.round((lyricScroller.height - lyricScroller.rowHeight * 3) / 2)) - lyricScroller.scrollOffset

                    Repeater {
                        model: 3

                        delegate: StyledText {
                            id: lyricRow
                            required property int index
                            readonly property int role: index - 1 // -1 previous, 0 current, 1 next
                            // 1 when this row owns the centre, 0 when it's a neighbour.
                            // Mid-animation the outgoing and incoming rows swap across it.
                            readonly property real activeness: role === 0 ? 1 - lyricScroller.progress : (role < 0) === lyricScroller.movingForward ? lyricScroller.progress : 0

                            width: lyricScroller.width
                            height: lyricScroller.rowHeight
                            text: lyricScroller.texts[index]
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: role === 0 ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            opacity: lyricScroller.dimOpacity + (1 - lyricScroller.dimOpacity) * activeness
                            scale: lyricScroller.dimScale + (1 - lyricScroller.dimScale) * activeness
                        }
                    }
                }

                MouseArea { // Other buttons fall through to the media controls below
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    onPressed: {
                        GlobalStates.lyricsSelectorScreen = root.QsWindow.window?.screen ?? null;
                        GlobalStates.lyricsSelectorOpen = !GlobalStates.lyricsSelectorOpen;
                    }
                }
            }
        }

        RippleButton {
            Layout.alignment: Qt.AlignVCenter
            visible: Config.options.bar.verbose
            implicitWidth: 24
            implicitHeight: 24
            toggled: LyricsService.lyricsEnabled
            downAction: () => Config.options.bar.media.showLyrics = !Config.options.bar.media.showLyrics

            colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
            colBackgroundHover: Appearance.colors.colLayer1Hover
            colRipple: Appearance.colors.colLayer1Active
            colBackgroundToggled: Appearance.colors.colSecondaryContainer
            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
            colRippleToggled: Appearance.colors.colSecondaryContainerActive

            contentItem: MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                fill: 1
                horizontalAlignment: Text.AlignHCenter
                color: LyricsService.lyricsEnabled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                text: "lyrics"
            }
        }

    }

    LyricsSelector {
        anchorItem: lyricScroller
    }

}
