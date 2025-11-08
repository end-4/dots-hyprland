import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

StyledPopup {
    id: root

    // Helper function to format KB to GB
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "memory"
                label: "RAM"
            }

            Column {
                spacing: 4

                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.memoryUsed)
                }

                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.memoryFree)
                }

                StyledPopupValueRow {
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

            StyledPopupHeaderRow {
                icon: "swap_horiz"
                label: "Swap"
            }

            Column {
                spacing: 4

                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("Used:")
                    value: root.formatKB(ResourceUsage.swapUsed)
                }

                StyledPopupValueRow {
                    icon: "check_circle"
                    label: Translation.tr("Free:")
                    value: root.formatKB(ResourceUsage.swapFree)
                }

                StyledPopupValueRow {
                    icon: "empty_dashboard"
                    label: Translation.tr("Total:")
                    value: root.formatKB(ResourceUsage.swapTotal)
                }

            }

        }

        Column {
            anchors.top: parent.top
            spacing: 8

            StyledPopupHeaderRow {
                icon: "planner_review"
                label: "CPU"
            }

            Column {
                spacing: 4

                StyledPopupValueRow {
                    icon: "bolt"
                    label: Translation.tr("Load:")
                    value: (ResourceUsage.cpuUsage > 0.8 ? Translation.tr("High") : ResourceUsage.cpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(ResourceUsage.cpuUsage * 100)}%)`
                }

                StyledPopupValueRow {
                    icon: "planner_review"
                    label: Translation.tr("Freq:")
                    value: ` ${ Math.round(ResourceUsage.cpuFreqency * 100) / 100} GHz`
                }

                StyledPopupValueRow {
                    icon: "thermometer"
                    label: Translation.tr("Temp:")
                    value: ` ${ Math.round(ResourceUsage.cpuTemperature)} °C`
                }

            }

        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 8
            visible: GpuUsage.iGpuAvailable && (Config.options.bar.resources.gpuLayout == 1 || Config.options.bar.resources.gpuLayout == 2)

            StyledPopupHeaderRow {
                icon: "empty_dashboard"
                label: "IGPU"
            }

            ColumnLayout {
                StyledPopupValueRow {
                    icon: "bolt"
                    label: Translation.tr("Load:")
                    value: (GpuUsage.iGpuUsage > 0.8 ? Translation.tr("High") : GpuUsage.iGpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(GpuUsage.iGpuUsage  * 100)}%)`
                }

                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("VRAM:")
                    value: ` ${Math.round(GpuUsage.iGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.iGpuVramTotalGB * 10) / 10} GB`
                }

                StyledPopupValueRow {
                    icon: "thermometer"
                    label: Translation.tr("Temp:")
                    value: `${GpuUsage.iGpuTempemperature} °C`
                }

            }

        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            spacing: 8
            visible: GpuUsage.dGpuAvailable && (Config.options.bar.resources.gpuLayout == 0 || Config.options.bar.resources.gpuLayout == 2)

            StyledPopupHeaderRow {
                icon: "empty_dashboard"
                label: "DGPU"
            }

            ColumnLayout {
                StyledPopupValueRow {
                    icon: "bolt"
                    label: Translation.tr("Load:")
                    value: (GpuUsage.dGpuUsage > 0.8 ? Translation.tr("High") : GpuUsage.dGpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(GpuUsage.dGpuUsage  * 100)}%)`
                }

                StyledPopupValueRow {
                    icon: "clock_loader_60"
                    label: Translation.tr("VRAM:")
                    value: ` ${Math.round(GpuUsage.dGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.dGpuVramTotalGB * 10) / 10} GB`
                }

                StyledPopupValueRow {
                    icon: "thermometer"
                    label: Translation.tr("Temp:")
                    value: `${GpuUsage.dGpuTempemperature} °C`
                }

            }

        }

    }

}
