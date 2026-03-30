import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * YouTube Downloader Settings Page.
 * Configure download path, quality, and format.
 */
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "download"
        title: Translation.tr("Download Settings")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Download path (e.g. ~/Downloads)")
            text: YtDownloader.downloadPath
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Qt.callLater(() => { YtDownloader.downloadPath = text })
            }
        }
    }

    ContentSection {
        icon: "high_quality"
        title: Translation.tr("Quality")

        ContentSubsection {
            title: Translation.tr("Video quality")

            ConfigSelectionArray {
                currentValue: YtDownloader.quality
                onSelected: newValue => { YtDownloader.quality = newValue }
                options: [
                    { displayName: Translation.tr("Best"),   icon: "star",        value: "best"  },
                    { displayName: "1080p",                  icon: "hd",          value: "1080p" },
                    { displayName: "720p",                   icon: "sd",          value: "720p"  },
                    { displayName: "480p",                   icon: "low_priority", value: "480p" },
                    { displayName: Translation.tr("Audio"),  icon: "music_note",  value: "audio" }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Output format")
            visible: YtDownloader.quality !== "audio"

            ConfigSelectionArray {
                currentValue: YtDownloader.format
                onSelected: newValue => { YtDownloader.format = newValue }
                options: [
                    { displayName: "mp4",  icon: "videocam",      value: "mp4"  },
                    { displayName: "mkv",  icon: "movie",         value: "mkv"  },
                    { displayName: "webm", icon: "web",           value: "webm" },
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Audio format")
            visible: YtDownloader.quality === "audio"

            ConfigSelectionArray {
                currentValue: YtDownloader.format
                onSelected: newValue => { YtDownloader.format = newValue }
                options: [
                    { displayName: "mp3",  icon: "music_note",    value: "mp3"  },
                    { displayName: "opus", icon: "spatial_audio",  value: "opus" },
                ]
            }
        }
    }

    ContentSection {
        icon: "info"
        title: Translation.tr("Options")

        ConfigSwitch {
            buttonIcon: "label"
            text: Translation.tr("Embed metadata (title, artist, thumbnail)")
            checked: YtDownloader.addMetadata
            onCheckedChanged: { YtDownloader.addMetadata = checked }
        }
    }

    NoticeBox {
        Layout.fillWidth: true
        text: Translation.tr("Requires yt-dlp to be installed. Install with: yay -S yt-dlp\nUse the YouTube Downloader panel (accessible from the Start menu waffle) to add URLs and track progress.")
    }
}
