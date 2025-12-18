import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.utils
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    readonly property bool lyricsEnabled: Config.options.bar.media?.showLyrics ?? false

    Layout.fillHeight: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: Appearance.sizes.barHeight

    LrclibLyrics {
        id: lrclibLyrics
        enabled: root.lyricsEnabled && (root.activePlayer?.trackTitle?.length > 0) && (root.activePlayer?.trackArtist?.length > 0)
        title: root.activePlayer?.trackTitle ?? ""
        artist: root.activePlayer?.trackArtist ?? ""
        duration: root.activePlayer?.length ?? 0
        position: root.activePlayer?.position ?? 0
    }

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: (root.lyricsEnabled && lrclibLyrics.lines.length > 0) ? 250 : Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    component LyricLine: Item {
        id: lyricLine
        required property string text

        property color color: Appearance.colors.colOnLayer1
        property int pixelSize: Appearance.font.pixelSize.smallie
        property int rowHeight: 0
        property bool bold: false
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
            font.bold: lyricLine.bold
            scale: lyricLine.textScale
            transformOrigin: Item.Center
            lineHeightMode: lyricLine.rowHeight > 0 ? Text.FixedHeight : Text.ProportionalHeight
            lineHeight: lyricLine.rowHeight > 0 ? lyricLine.rowHeight : 1.0
        }
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

        Item {
            id: mediaTextContainer
            visible: Config.options.bar.verbose
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: rowLayout.spacing
            clip: true

            readonly property bool showLyricsLine: root.lyricsEnabled && lrclibLyrics.enabled

            StyledText {
                id: normalText
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: Appearance.colors.colOnLayer1
                text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
                visible: !mediaTextContainer.showLyricsLine
            }

            Item {
                id: lyricScroller
                anchors.fill: parent
                visible: mediaTextContainer.showLyricsLine
                clip: true

                readonly property bool hasSyncedLines: lrclibLyrics.lines.length > 0
                readonly property int rowHeight: Math.max(10, Math.min(Math.floor(height / 3), Appearance.font.pixelSize.smallie))
                readonly property real baseY: Math.max(0, Math.round((height - rowHeight * 3) / 2))
                readonly property real downScale: Appearance.font.pixelSize.smaller / Appearance.font.pixelSize.smallie
                
                readonly property int targetCurrentIndex: hasSyncedLines ? lrclibLyrics.currentIndex : -1
                
                readonly property string targetPrev: hasSyncedLines ? lrclibLyrics.prevLineText : ""
                readonly property string targetCurrent: hasSyncedLines ? (lrclibLyrics.currentLineText || "♪") : lrclibLyrics.displayText
                readonly property string targetNext: hasSyncedLines ? lrclibLyrics.nextLineText : ""

                // Track index changes for animation
                property int lastIndex: -1
                property bool isMovingForward: true
                
                onTargetCurrentIndexChanged: {
                    if (targetCurrentIndex !== lastIndex) {
                        isMovingForward = targetCurrentIndex > lastIndex;
                        lastIndex = targetCurrentIndex;
                        scrollAnimation.restart();
                    }
                }

                // Animation for smooth scrolling effect
                property real scrollOffset: 0
                
                SequentialAnimation {
                    id: scrollAnimation
                    // Instant jump to offset
                    PropertyAction { 
                        target: lyricScroller
                        property: "scrollOffset"
                        value: lyricScroller.isMovingForward ? -lyricScroller.rowHeight : lyricScroller.rowHeight 
                    }
                    // Smooth slide to 0
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
                        
                        // If moving forward, this was Current, so fade out. Else stay dim.
                        property real dynamicOpacity: (lyricScroller.isMovingForward) 
                            ? lyricScroller.dimOpacity + (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                            : lyricScroller.dimOpacity
                            
                        property real dynamicScale: (lyricScroller.isMovingForward)
                            ? lyricScroller.downScale + (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                            : lyricScroller.downScale

                        opacity: dynamicOpacity
                        textScale: dynamicScale
                    }

                    LyricLine {
                        width: parent.width
                        rowHeight: lyricScroller.rowHeight
                        text: lyricScroller.targetCurrent
                        color: Appearance.colors.colOnLayer1
                        pixelSize: Appearance.font.pixelSize.smallie
                        
                        // Always fading in from dim (whether from Next or Prev)
                        property real dynamicOpacity: lyricScroller.activeOpacity - (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress

                        property real dynamicScale: 1.0 - (1.0 - lyricScroller.downScale) * lyricScroller.animProgress

                        opacity: dynamicOpacity
                        textScale: dynamicScale
                    }

                    LyricLine {
                        width: parent.width
                        rowHeight: lyricScroller.rowHeight
                        text: lyricScroller.targetNext
                        color: Appearance.colors.colSubtext
                        pixelSize: Appearance.font.pixelSize.smallie
                        
                        // If moving backward, this was Current, so fade out. Else stay dim.
                        property real dynamicOpacity: (!lyricScroller.isMovingForward)
                            ? lyricScroller.dimOpacity + (lyricScroller.activeOpacity - lyricScroller.dimOpacity) * lyricScroller.animProgress
                            : lyricScroller.dimOpacity

                        property real dynamicScale: (!lyricScroller.isMovingForward)
                            ? lyricScroller.downScale + (1.0 - lyricScroller.downScale) * lyricScroller.animProgress
                            : lyricScroller.downScale

                        opacity: dynamicOpacity
                        textScale: dynamicScale
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
