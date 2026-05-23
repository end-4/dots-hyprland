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
    readonly property bool lyricsEnabled: LyricsService.lyricsEnabled

    function handleMediaClick(event) {
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

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: (root.lyricsEnabled && LyricsService.lines.length > 0) ? 250 : Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    component LyricLine: Item {
        id: lyricLine
        required property string text

        property color color: Appearance.colors.colOnLayer1
        property int pixelSize: Appearance.font.pixelSize.smallie
        property int rowHeight: 0
        property real textScale: 1.0

        clip: true
        implicitHeight: lyricLine.rowHeight > 0 ? lyricLine.rowHeight : lineText.implicitHeight

        StyledText {
            id: lineText
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            text: lyricLine.text
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            color: lyricLine.color
            font.pixelSize: lyricLine.pixelSize
            scale: lyricLine.textScale
            transformOrigin: Item.Center
            lineHeightMode: lyricLine.rowHeight > 0 ? Text.FixedHeight : Text.ProportionalHeight
            lineHeight: lyricLine.rowHeight > 0 ? lyricLine.rowHeight : 1.0
        }
    }

    RowLayout {
        id: rowLayout
        spacing: 4
        anchors.fill: parent

        Item {
            id: mediaIndicator
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: mediaCircProg.implicitWidth
            implicitHeight: mediaCircProg.implicitHeight

            ClippedFilledCircularProgress {
                id: mediaCircProg
                anchors.fill: parent
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

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
                onPressed: (event) => root.handleMediaClick(event)
            }
        }

        Item {
            id: mediaTextContainer
            visible: Config.options.bar.verbose
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: rowLayout.spacing
            clip: true

            readonly property bool showLyricsLine: root.lyricsEnabled && LyricsService.hasTrack

            StyledText {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: Appearance.colors.colOnLayer1
                text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
                visible: !mediaTextContainer.showLyricsLine
            }

            MouseArea {
                anchors.fill: parent
                visible: !mediaTextContainer.showLyricsLine
                acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
                onPressed: (event) => root.handleMediaClick(event)
            }

            Item {
                id: lyricScroller
                anchors.fill: parent
                visible: mediaTextContainer.showLyricsLine
                clip: true

                readonly property bool hasSyncedLines: LyricsService.lines.length > 0
                readonly property int rowHeight: Math.max(10, Math.min(Math.floor(height / 3), Appearance.font.pixelSize.smallie))
                readonly property real baseY: Math.max(0, Math.round((height - rowHeight * 3) / 2))
                readonly property real downScale: Appearance.font.pixelSize.smaller / Appearance.font.pixelSize.smallie

                readonly property int targetCurrentIndex: hasSyncedLines ? LyricsService.currentIndex : -1

                readonly property string targetPrev: hasSyncedLines ? LyricsService.prevLineText : ""
                readonly property string targetCurrent: hasSyncedLines ? (LyricsService.currentLineText || "♪") : LyricsService.displayText
                readonly property string targetNext: hasSyncedLines ? LyricsService.nextLineText : ""

                property int lastIndex: -1
                property bool isMovingForward: true

                onTargetCurrentIndexChanged: {
                    if (targetCurrentIndex !== lastIndex) {
                        isMovingForward = targetCurrentIndex > lastIndex;
                        lastIndex = targetCurrentIndex;
                        scrollAnimation.restart();
                    }
                }

                property real scrollOffset: 0

                SequentialAnimation {
                    id: scrollAnimation
                    PropertyAction {
                        target: lyricScroller
                        property: "scrollOffset"
                        value: lyricScroller.isMovingForward ? -lyricScroller.rowHeight : lyricScroller.rowHeight
                    }
                    NumberAnimation {
                        target: lyricScroller
                        property: "scrollOffset"
                        to: 0
                        duration: 300
                        easing.type: Easing.OutCubic
                    }
                }

                readonly property real animProgress: Math.abs(scrollOffset) / rowHeight
                readonly property real dimOpacity: 0.6
                readonly property real activeOpacity: 1.0

                Column {
                    width: parent.width
                    spacing: 0
                    y: lyricScroller.baseY - lyricScroller.scrollOffset

                    LyricLine {
                        width: parent.width
                        rowHeight: lyricScroller.rowHeight
                        text: lyricScroller.targetPrev
                        color: Appearance.colors.colSubtext
                        pixelSize: Appearance.font.pixelSize.smallie
                        opacity: lyricScroller.isMovingForward
                            ? lyricScroller.dimOpacity + (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                            : lyricScroller.dimOpacity
                        textScale: lyricScroller.isMovingForward
                            ? lyricScroller.downScale + (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                            : lyricScroller.downScale
                    }

                    LyricLine {
                        width: parent.width
                        rowHeight: lyricScroller.rowHeight
                        text: lyricScroller.targetCurrent
                        color: Appearance.colors.colOnLayer1
                        pixelSize: Appearance.font.pixelSize.smallie
                        opacity: lyricScroller.activeOpacity - (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                        textScale: 1.0 - (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                    }

                    LyricLine {
                        width: parent.width
                        rowHeight: lyricScroller.rowHeight
                        text: lyricScroller.targetNext
                        color: Appearance.colors.colSubtext
                        pixelSize: Appearance.font.pixelSize.smallie
                        opacity: !lyricScroller.isMovingForward
                            ? lyricScroller.dimOpacity + (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                            : lyricScroller.dimOpacity
                        textScale: !lyricScroller.isMovingForward
                            ? lyricScroller.downScale + (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                            : lyricScroller.downScale
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
                    onPressed: (event) => {
                        if (event.button === Qt.LeftButton) {
                            const center = root.QsWindow?.mapFromItem(lyricScroller, lyricScroller.width / 2, lyricScroller.height / 2);
                            if (center && typeof center.x === "number")
                                GlobalStates.lyricsSelectorAnchorCenterX = center.x;
                            GlobalStates.lyricsSelectorOpen = !GlobalStates.lyricsSelectorOpen;
                            return;
                        }
                        root.handleMediaClick(event)
                    }
                }
            }
        }

        RippleButton {
            Layout.alignment: Qt.AlignVCenter
            visible: Config.options.bar.verbose
            implicitWidth: 24
            implicitHeight: 24
            toggled: root.lyricsEnabled
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
                color: root.lyricsEnabled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                text: "lyrics"
            }
        }
    }
}
