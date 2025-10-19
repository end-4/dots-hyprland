import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    component ResourceItem: RowLayout {
        id: resourceItem
        required property string icon
        required property string label
        required property string value
        spacing: 4

        MaterialSymbol {
            text: resourceItem.icon
            color: Appearance.colors.colOnSurfaceVariant
            iconSize: Appearance.font.pixelSize.large
        }
        StyledText {
            text: resourceItem.label
            color: Appearance.colors.colOnSurfaceVariant
        }
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            visible: resourceItem.value !== ""
            color: Appearance.colors.colOnSurfaceVariant
            text: resourceItem.value
        }
    }

    component ResourceHeaderItem: Row {
        id: headerItem
        required property var icon
        required property var label
        spacing: 5

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 0
            font.weight: Font.Medium
            text: headerItem.icon
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnSurfaceVariant
        }

        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: headerItem.label
            font {
                weight: Font.Medium
                pixelSize: Appearance.font.pixelSize.normal
            }
            color: Appearance.colors.colOnSurfaceVariant
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Column {
            anchors.top: parent.top
            spacing: 8

            ResourceHeaderItem {
                icon: "memory"
                label: "RAM"
            }
            Column {
                spacing: 4
                ResourceItem {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.memoryUsed)
                }
                ResourceItem {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.memoryFree)
                }
                ResourceItem {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.memoryTotal)
                }
            }
        }

        Column {
            visible: ResourceUsage.swapTotal > 0
            anchors.top: parent.top
            spacing: 8

            ResourceHeaderItem {
                icon: "swap_horiz"
                label: "Swap"
            }
            Column {
                spacing: 4
                ResourceItem {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.swapUsed)
                }
                ResourceItem {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.swapFree)
                }
                ResourceItem {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.swapTotal)
                }
            }
        }

        Column {
            anchors.top: parent.top
            spacing: 8

            ResourceHeaderItem {
                icon: "planner_review"
                label: "CPU"
            }
            Column {
                spacing: 4
                ResourceItem {
                    icon: "bolt"
                    label: Translation.tr("Load:")
                    value: (ResourceUsage.cpuUsage > 0.8 ? Translation.tr("High") : ResourceUsage.cpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(ResourceUsage.cpuUsage * 100)}%)`
                }
            }
        }
    }
}
