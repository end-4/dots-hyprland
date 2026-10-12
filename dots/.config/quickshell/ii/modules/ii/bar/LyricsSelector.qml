pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

/**
 * Lets the user override the automatic lrclib match when it picks the wrong
 * version of a track. Lives in the bar so it can anchor under the lyrics.
 */
LazyLoader {
    id: root

    property Item anchorItem
    readonly property real widgetWidth: 520

    // One bar per screen, so only the one that was clicked should open
    active: GlobalStates.lyricsSelectorOpen && root.QsWindow?.window?.screen === GlobalStates.lyricsSelectorScreen

    component: PanelWindow {
        id: selectorWindow

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        implicitWidth: root.widgetWidth + Appearance.sizes.elevationMargin * 2
        implicitHeight: selectorBackground.implicitHeight + Appearance.sizes.elevationMargin * 2
        color: "transparent"
        WlrLayershell.namespace: "quickshell:lyricsSelector"
        WlrLayershell.layer: WlrLayer.Overlay

        // Lyrics are only shown on the horizontal bar, so there's no vertical case
        anchors {
            top: !Config.options.bar.bottom
            bottom: Config.options.bar.bottom
            left: true
        }
        margins {
            top: Appearance.sizes.barHeight
            bottom: Appearance.sizes.barHeight
            // Centre under the lyrics, kept within the screen
            left: Math.max(0, Math.min(root.QsWindow?.mapFromItem(root.anchorItem, (root.anchorItem.width - selectorWindow.implicitWidth) / 2, 0).x ?? 0, selectorWindow.screen.width - selectorWindow.implicitWidth))
        }

        mask: Region {
            item: selectorBackground
        }

        Component.onCompleted: GlobalFocusGrab.addDismissable(selectorWindow)
        Component.onDestruction: GlobalFocusGrab.removeDismissable(selectorWindow)
        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.lyricsSelectorOpen = false;
            }
        }

        StyledRectangularShadow {
            target: selectorBackground
        }

        Rectangle {
            id: selectorBackground
            property real padding: 14

            anchors.centerIn: parent
            implicitWidth: root.widgetWidth
            implicitHeight: contentLayout.implicitHeight + padding * 2
            // Gaps larger than the screen rounding would otherwise give a negative radius
            radius: Math.max(0, Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1)
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                anchors.margins: selectorBackground.padding
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    MaterialSymbol {
                        text: "lyrics"
                        fill: 1
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colOnLayer0
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.large
                            elide: Text.ElideRight
                            text: Translation.tr("Select lyrics")
                        }
                        StyledText {
                            Layout.fillWidth: true
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                            text: `${LyricsService.queryTitle}${LyricsService.queryArtist ? " • " + LyricsService.queryArtist : ""}`
                        }
                    }

                    RippleButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        buttonRadius: Appearance.rounding.full
                        downAction: () => GlobalStates.lyricsSelectorOpen = false

                        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active

                        contentItem: MaterialSymbol {
                            text: "close"
                            fill: 1
                            iconSize: Appearance.font.pixelSize.larger
                            horizontalAlignment: Text.AlignHCenter
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: LyricsService.loading || LyricsService.error.length > 0
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    text: LyricsService.loading ? Translation.tr("Fetching lyric matches…") : LyricsService.error
                }

                Repeater {
                    // A leading id-0 entry stands for the automatic match
                    model: LyricsService.options.length > 0 ? [{ id: 0 }, ...LyricsService.options] : []

                    delegate: RippleButton {
                        id: entry
                        required property var modelData
                        readonly property bool isAutomatic: modelData.id === 0
                        readonly property bool isSelected: LyricsService.selectedId === modelData.id
                        // Duration is often the only thing telling two entries apart
                        readonly property string label: isAutomatic ? Translation.tr("Use automatic match") : [modelData.trackName, modelData.artistName, modelData.duration > 0 ? StringUtils.friendlyTimeForSeconds(modelData.duration) : ""].filter(part => part.length > 0).join(" • ")

                        Layout.fillWidth: true
                        implicitHeight: entryLayout.implicitHeight + 12
                        buttonRadius: Appearance.rounding.small
                        toggled: isSelected
                        downAction: () => {
                            LyricsService.setSelectedIdForCurrentTrack(modelData.id);
                            GlobalStates.lyricsSelectorOpen = false;
                        }

                        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1, 1)
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        colBackgroundToggled: Appearance.m3colors.m3secondaryContainer
                        colBackgroundToggledHover: Appearance.m3colors.m3secondaryContainer
                        colRippleToggled: Appearance.m3colors.m3secondaryContainer

                        contentItem: ColumnLayout {
                            id: entryLayout
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledText {
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.smallie
                                    font.bold: entry.isSelected
                                    elide: Text.ElideRight
                                    text: entry.label
                                    color: entry.isSelected ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0
                                }

                                MaterialSymbol {
                                    visible: entry.isSelected
                                    text: "check_circle"
                                    fill: 1
                                    iconSize: Appearance.font.pixelSize.large
                                    color: Appearance.m3colors.m3onSecondaryContainer
                                }
                            }

                            StyledText { // Preview of where this candidate is right now
                                Layout.fillWidth: true
                                visible: !entry.isAutomatic
                                font.pixelSize: Appearance.font.pixelSize.small
                                elide: Text.ElideRight
                                text: LyricsService.lineTextForOption(entry.modelData, LyricsService.position)
                                color: entry.isSelected ? ColorUtils.transparentize(Appearance.m3colors.m3onSecondaryContainer, 0.1) : Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }
        }
    }
}
