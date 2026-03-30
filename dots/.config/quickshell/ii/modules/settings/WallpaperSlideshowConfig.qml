import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

/**
 * Wallpaper Slideshow Settings Page.
 * Exposed as a top-level tab in settings.qml ("Slideshow").
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "slideshow"
        title: Translation.tr("Wallpaper Slideshow")

        // Enable toggle + countdown display on same row
        RowLayout {
            Layout.fillWidth: true

            ConfigSwitch {
                buttonIcon: "play_circle"
                text: Translation.tr("Enable slideshow")
                checked: WallpaperSlideshow.enabled
                onCheckedChanged: {
                    WallpaperSlideshow.enabled = checked
                }
                StyledToolTip {
                    text: Translation.tr("Automatically rotate wallpapers from the selected folder")
                }
            }

            Item { Layout.fillWidth: true }

            // Countdown badge
            Rectangle {
                visible: WallpaperSlideshow.enabled
                radius: Appearance.rounding.full
                color: Appearance.colors.colSecondaryContainer
                implicitWidth: countdownLabel.implicitWidth + 20
                implicitHeight: 32

                StyledText {
                    id: countdownLabel
                    anchors.centerIn: parent
                    text: "⏱ " + WallpaperSlideshow.countdownText
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }

        // Status message
        StyledText {
            visible: WallpaperSlideshow.statusMessage.length > 0
            text: WallpaperSlideshow.statusMessage
            font.pixelSize: Appearance.font.pixelSize.smallie
            color: Appearance.colors.colSubtext
            Layout.leftMargin: 10
        }
    }

    ContentSection {
        icon: "timer"
        title: Translation.tr("Interval")

        ConfigSpinBox {
            icon: "schedule"
            text: Translation.tr("Minutes between wallpaper changes")
            value: WallpaperSlideshow.intervalMinutes
            from: 1
            to: 120
            stepSize: 1
            onValueChanged: {
                WallpaperSlideshow.intervalMinutes = value
            }
        }
    }

    ContentSection {
        icon: "folder_open"
        title: Translation.tr("Wallpaper Folder")

        ContentSubsection {
            title: Translation.tr("Current folder")
            tooltip: Translation.tr("Images from this folder will be used for the slideshow")

            RowLayout {
                Layout.fillWidth: true

                MaterialTextArea {
                    id: folderInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Path to folder, e.g. ~/Pictures/Wallpapers")
                    text: WallpaperSlideshow.folder
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        Qt.callLater(() => {
                            WallpaperSlideshow.setFolder(text)
                        })
                    }
                }

                RippleButtonWithIcon {
                    Layout.fillHeight: true
                    materialIcon: "folder_open"
                    mainText: Translation.tr("Browse")
                    buttonRadius: Appearance.rounding.small
                    onClicked: {
                        // Open the Wallpapers selector dialog (reuses existing infrastructure)
                        Quickshell.execDetached([
                            "bash", "-c",
                            `zenity --file-selection --directory --title="Select Wallpaper Folder" 2>/dev/null | tr -d '\\n' | xargs -I{} qs ipc call wallpapers apply {}`
                        ])
                    }
                    StyledToolTip {
                        text: Translation.tr("Browse for a folder containing images")
                    }
                }
            }

            // Wallpaper count badge
            StyledText {
                text: Translation.tr("%1 image(s) found in folder").arg(Wallpapers.wallpapers.length)
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: Appearance.colors.colSubtext
                Layout.leftMargin: 10
            }
        }
    }

    ContentSection {
        icon: "shuffle"
        title: Translation.tr("Actions")

        ConfigRow {
            RippleButtonWithIcon {
                Layout.fillWidth: true
                materialIcon: "skip_next"
                mainText: Translation.tr("Next wallpaper now")
                buttonRadius: Appearance.rounding.small
                enabled: WallpaperSlideshow.enabled
                onClicked: {
                    WallpaperSlideshow.skipToNext()
                }
                StyledToolTip {
                    text: Translation.tr("Immediately switch to a random wallpaper and reset the timer")
                }
            }

            RippleButtonWithIcon {
                Layout.fillWidth: true
                materialIcon: "shuffle"
                mainText: Translation.tr("Random (one-shot)")
                buttonRadius: Appearance.rounding.small
                onClicked: {
                    Wallpapers.randomFromCurrentFolder()
                }
                StyledToolTip {
                    text: Translation.tr("Pick a random wallpaper right now without affecting the timer")
                }
            }
        }
    }

    NoticeBox {
        Layout.fillWidth: true
        text: Translation.tr("The slideshow runs inside Quickshell and requires no separate autostart entry. It will resume automatically each login as long as Quickshell starts.")
    }
}
