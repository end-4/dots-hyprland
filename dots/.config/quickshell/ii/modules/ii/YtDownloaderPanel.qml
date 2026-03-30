pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

/**
 * YouTube Downloader panel.
 * Paste a URL, track download progress. Used in the waffle/left-sidebar area.
 */
Item {
    id: root
    implicitWidth: 380
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 8

        // ── URL Input ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialTextField {
                id: urlInput
                Layout.fillWidth: true
                placeholderText: Translation.tr("Paste YouTube URL here…")
                onAccepted: _startDownload()
                KeyNavigation.right: downloadBtn
            }

            RippleButton {
                id: downloadBtn
                implicitWidth: 44
                implicitHeight: 44
                buttonRadius: Appearance.rounding.full
                enabled: urlInput.text.trim().length > 0
                onClicked: _startDownload()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "download"
                    iconSize: 20
                    color: Appearance.colors.colOnPrimaryContainer
                }
                colBackground: Appearance.colors.colPrimaryContainer
                colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                StyledToolTip { text: Translation.tr("Start download") }
            }
        }

        // ── Queue header ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: YtDownloader.queue.length > 0

            StyledText {
                text: Translation.tr("Downloads (%1)").arg(YtDownloader.queue.length)
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                Layout.fillWidth: true
            }

            RippleButton {
                implicitWidth: 28
                implicitHeight: 28
                buttonRadius: Appearance.rounding.full
                visible: YtDownloader.queue.some(i => i.status === "done" || i.status === "error")
                onClicked: YtDownloader.clearCompleted()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "clear_all"
                    iconSize: 16
                    color: Appearance.colors.colSubtext
                }
                StyledToolTip { text: Translation.tr("Clear completed") }
            }
        }

        // ── Queue list ────────────────────────────────────────────────────
        StyledListView {
            id: queueList
            Layout.fillWidth: true
            implicitHeight: Math.min(contentHeight, 300)
            visible: YtDownloader.queue.length > 0
            model: YtDownloader.queue
            spacing: 6

            delegate: QueueItem {
                required property var modelData
                width: queueList.width
                item: modelData
            }
        }

        // ── Empty state ───────────────────────────────────────────────────
        PagePlaceholder {
            visible: YtDownloader.queue.length === 0
            Layout.fillWidth: true
            icon: "download"
            text: Translation.tr("No downloads yet")
            subtext: Translation.tr("Paste a YouTube link above and press Enter")
        }
    }

    // ── Component for individual queue items ──────────────────────────────
    component QueueItem: Item {
        required property var item
        implicitHeight: itemCol.implicitHeight + 16

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
        }

        ColumnLayout {
            id: itemCol
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Status icon
                MaterialSymbol {
                    text: {
                        switch (item.status) {
                            case "done":        return "check_circle"
                            case "error":       return "error"
                            case "downloading": return "downloading"
                            default:            return "schedule"
                        }
                    }
                    iconSize: 16
                    color: {
                        switch (item.status) {
                            case "done":        return Appearance.colors.colPositive ?? "#4caf50"
                            case "error":       return Appearance.colors.colNegative ?? "#f44336"
                            case "downloading": return Appearance.colors.colPrimary
                            default:            return Appearance.colors.colSubtext
                        }
                    }
                }

                // Title
                StyledText {
                    Layout.fillWidth: true
                    text: item.title || item.url
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }

                // Retry button (on error)
                RippleButton {
                    visible: item.status === "error"
                    implicitWidth: 22
                    implicitHeight: 22
                    buttonRadius: Appearance.rounding.full
                    onClicked: YtDownloader.retryDownload(item.id)
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "refresh"
                        iconSize: 14
                        color: Appearance.colors.colOnSurface
                    }
                    StyledToolTip { text: Translation.tr("Retry") }
                }

                // Cancel button (while downloading/queued)
                RippleButton {
                    visible: item.status === "downloading" || item.status === "queued"
                    implicitWidth: 22
                    implicitHeight: 22
                    buttonRadius: Appearance.rounding.full
                    onClicked: YtDownloader.cancelDownload(item.id)
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 14
                        color: Appearance.colors.colOnSurface
                    }
                    StyledToolTip { text: Translation.tr("Cancel") }
                }
            }

            // Progress bar
            StyledProgressBar {
                Layout.fillWidth: true
                visible: item.status === "downloading"
                value: item.progress
                valueBarHeight: 4
            }

            // Error message
            StyledText {
                visible: item.status === "error" && item.error.length > 0
                Layout.fillWidth: true
                text: item.error
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: Appearance.colors.colNegative ?? "#f44336"
                wrapMode: Text.WordWrap
            }

            // Progress % text
            StyledText {
                visible: item.status === "downloading"
                text: Math.round(item.progress * 100) + "%"
                font.pixelSize: Appearance.font.pixelSize.smallie
                color: Appearance.colors.colSubtext
            }
        }
    }

    function _startDownload() {
        const url = urlInput.text.trim()
        if (!url) return
        YtDownloader.download(url)
        urlInput.text = ""
    }
}
