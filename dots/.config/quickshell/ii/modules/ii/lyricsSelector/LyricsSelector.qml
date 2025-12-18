pragma ComponentBehavior: Bound

import qs.services
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    readonly property real widgetWidth: 520
    property real popupRounding: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

    Loader {
        id: selectorLoader
        active: GlobalStates.lyricsSelectorOpen

        sourceComponent: PanelWindow {
            id: selectorWindow
            visible: true

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: root.widgetWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: selectorBackground.implicitHeight + Appearance.sizes.elevationMargin * 2
            color: "transparent"
            WlrLayershell.namespace: "quickshell:lyricsSelector"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: !Config.options.bar.bottom || Config.options.bar.vertical
                bottom: Config.options.bar.bottom && !Config.options.bar.vertical
                left: !(Config.options.bar.vertical && Config.options.bar.bottom)
                right: Config.options.bar.vertical && Config.options.bar.bottom
            }
            margins {
                top: Config.options.bar.vertical ? ((selectorWindow.screen.height / 2) - (selectorWindow.implicitHeight / 2)) : Appearance.sizes.barHeight
                bottom: Appearance.sizes.barHeight
                left: Config.options.bar.vertical ? Appearance.sizes.barHeight : ((selectorWindow.screen.width / 2) - (selectorWindow.implicitWidth / 2))
                right: Appearance.sizes.barHeight
            }

            mask: Region { item: selectorBackground }

            HyprlandFocusGrab {
                windows: [selectorWindow]
                active: selectorLoader.active
                onCleared: () => {
                    if (!active)
                        GlobalStates.lyricsSelectorOpen = false;
                }
            }

            StyledRectangularShadow {
                target: selectorBackground
            }

            Rectangle {
                id: selectorBackground
                anchors.centerIn: parent
                implicitWidth: root.widgetWidth
                implicitHeight: contentLayout.implicitHeight + padding * 2
                radius: root.popupRounding
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                property real padding: 14

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
                        visible: LyricsService.loading
                        color: Appearance.colors.colSubtext
                        text: Translation.tr("Fetching lyric matches…")
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: !LyricsService.loading && LyricsService.error.length > 0
                        color: Appearance.colors.colSubtext
                        text: LyricsService.error
                        font.pixelSize: Appearance.font.pixelSize.small
                    }

                    ColumnLayout {
                        id: optionsColumn
                        Layout.fillWidth: true
                        spacing: 6
                        visible: !LyricsService.loading && LyricsService.options.length > 0

                        Repeater {
                            model: LyricsService.options

                            delegate: RippleButton {
                                required property var modelData

                                readonly property bool isSelected: LyricsService.selectedId > 0 && LyricsService.selectedId === (modelData?.id ?? 0)

                                Layout.fillWidth: true
                                implicitHeight: optionLayout.implicitHeight + 12

                                buttonRadius: Appearance.rounding.small
                                toggled: isSelected
                                downAction: () => {
                                    LyricsService.setSelectedIdForCurrentTrack(modelData?.id ?? 0);
                                    GlobalStates.lyricsSelectorOpen = false;
                                }

                                colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1, 1)
                                colBackgroundHover: Appearance.colors.colLayer1Hover
                                colRipple: Appearance.colors.colLayer1Active
                                colBackgroundToggled: Appearance.m3colors.m3secondaryContainer
                                colBackgroundToggledHover: Appearance.m3colors.m3secondaryContainer
                                colRippleToggled: Appearance.m3colors.m3secondaryContainer

                                contentItem: Item {
                                    id: optionContent
                                    anchors.fill: parent
                                    anchors.margins: 6

                                    ColumnLayout {
                                        id: optionLayout
                                        anchors.fill: parent
                                        spacing: 2

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            StyledText {
                                                Layout.fillWidth: true
                                                font.pixelSize: Appearance.font.pixelSize.smallie
                                                elide: Text.ElideRight
                                                text: `${modelData?.trackName ?? ""}${modelData?.artistName ? " • " + modelData.artistName : ""}`
                                                color: isSelected ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0
                                                font.bold: isSelected
                                            }

                                            MaterialSymbol {
                                                visible: isSelected
                                                text: "check_circle"
                                                fill: 1
                                                iconSize: Appearance.font.pixelSize.large
                                                color: Appearance.m3colors.m3onSecondaryContainer
                                            }
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: isSelected ? ColorUtils.transparentize(Appearance.m3colors.m3onSecondaryContainer, 0.1) : Appearance.colors.colSubtext
                                            elide: Text.ElideRight
                                            text: LyricsService.currentLineForOption(modelData, LyricsService.position)
                                        }
                                    }
                                }
                            }
                        }

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            buttonRadius: Appearance.rounding.small
                            toggled: LyricsService.selectedId === 0
                            downAction: () => {
                                LyricsService.setSelectedIdForCurrentTrack(0);
                                GlobalStates.lyricsSelectorOpen = false;
                            }

                            colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1, 1)
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            colRipple: Appearance.colors.colLayer1Active
                            colBackgroundToggled: Appearance.m3colors.m3secondaryContainer
                            colBackgroundToggledHover: Appearance.m3colors.m3secondaryContainer
                            colRippleToggled: Appearance.m3colors.m3secondaryContainer

                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                MaterialSymbol {
                                    text: "auto_awesome"
                                    fill: 1
                                    iconSize: Appearance.font.pixelSize.large
                                    color: LyricsService.selectedId === 0 ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.smallie
                                    elide: Text.ElideRight
                                    text: Translation.tr("Use automatic match")
                                    color: LyricsService.selectedId === 0 ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0
                                    font.bold: LyricsService.selectedId === 0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
