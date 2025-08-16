import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: networkLayout.implicitWidth + 16
    implicitHeight: Appearance.sizes.barHeight

    // Display modes: 0=total, 1=download, 2=upload, 3=both
    property int displayMode: 0

    // Helper function to format network speed
    function formatSpeed(bytesPerSecond) {
        if (bytesPerSecond < 1024) {
            return bytesPerSecond.toFixed(0) + " B/s";
        } else if (bytesPerSecond < 1024 * 1024) {
            return (bytesPerSecond / 1024).toFixed(1) + " KB/s";
        } else if (bytesPerSecond < 1024 * 1024 * 1024) {
            return (bytesPerSecond / (1024 * 1024)).toFixed(1) + " MB/s";
        } else {
            return (bytesPerSecond / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
        }
    }

    function getDisplayText() {
        var downloadSpeed = ResourceUsage.networkDownloadSpeed;
        var uploadSpeed = ResourceUsage.networkUploadSpeed;
        var totalSpeed = downloadSpeed + uploadSpeed;

        switch (displayMode) {
        case 0 // Total speed
        :
            return formatSpeed(totalSpeed);
        case 1 // Download only
        :
            return "↓ " + formatSpeed(downloadSpeed);
        case 2 // Upload only
        :
            return "↑ " + formatSpeed(uploadSpeed);
        case 3 // Both (dual row)
        :
            return ""; // Handled separately
        default:
            return formatSpeed(totalSpeed);
        }
    }

    RowLayout {
        id: networkLayout
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            text: "network_check"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer1
        }

        // Single line display (modes 0, 1, 2)
        StyledText {
            id: singleLineText
            visible: displayMode !== 3
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: getDisplayText()
        }

        // Side by side display (mode 3)
        RowLayout {
            visible: displayMode === 3
            spacing: 4

            StyledText {
                id: downloadText
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                text: "↓ " + formatSpeed(ResourceUsage.networkDownloadSpeed)
            }

            StyledText {
                id: uploadText
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                text: "↑ " + formatSpeed(ResourceUsage.networkUploadSpeed)
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: {
            displayMode = (displayMode + 1) % 4;
        }
    }

    StyledPopup {
        hoverTarget: mouseArea

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            // Header
            RowLayout {
                spacing: 5

                MaterialSymbol {
                    fill: 0
                    font.weight: Font.Medium
                    text: "network_check"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    text: Translation.tr("Network Speed")
                    font {
                        weight: Font.Medium
                        pixelSize: Appearance.font.pixelSize.normal
                    }
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }

            // Speed info
            RowLayout {
                spacing: 5

                MaterialSymbol {
                    text: "download"
                    color: Appearance.colors.colOnSurfaceVariant
                    iconSize: Appearance.font.pixelSize.large
                }
                StyledText {
                    text: Translation.tr("Download:")
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    color: Appearance.colors.colOnSurfaceVariant
                    text: formatSpeed(ResourceUsage.networkDownloadSpeed)
                }
            }

            RowLayout {
                spacing: 5

                MaterialSymbol {
                    text: "upload"
                    color: Appearance.colors.colOnSurfaceVariant
                    iconSize: Appearance.font.pixelSize.large
                }
                StyledText {
                    text: Translation.tr("Upload:")
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    color: Appearance.colors.colOnSurfaceVariant
                    text: formatSpeed(ResourceUsage.networkUploadSpeed)
                }
            }
        }
    }
}
