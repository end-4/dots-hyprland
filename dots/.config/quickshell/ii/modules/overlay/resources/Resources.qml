pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import Qt.labs.synchronizer
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.overlay

StyledOverlayWidget {
    function formatKB(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

   id: root
   property list<var> resources: [
        {
            icon: "planner_review",
            name: Translation.tr("CPU"),
            history: ResourceUsage.cpuUsageHistory,
            maxAvailableString: ResourceUsage.maxAvailableCpuString,
            available: true,
              extraProperties: [
                {
                    icon: "bolt",
                    label: Translation.tr("Load:"),
                    value: (ResourceUsage.cpuUsage > 0.8 ? Translation.tr("High") : ResourceUsage.cpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(ResourceUsage.cpuUsage * 100)}%)`
                },
                {
                    icon: "planner_review",
                    label: Translation.tr("Freq:"),
                    value: ` ${Math.round(ResourceUsage.cpuFreqency  * 100) / 100} GHz`
                },
                {
                    icon: "thermometer",
                    label: Translation.tr("Temp:"),
                    value: ` ${Math.round(ResourceUsage.cpuTemperature)} °C`
                }
            ]
        },
        {
            icon: "memory",
            name: Translation.tr("RAM"),
            history: ResourceUsage.memoryUsageHistory,
            maxAvailableString: ResourceUsage.maxAvailableMemoryString,
            available: true,
            extraProperties: [
                {
                    icon: "clock_loader_60",
                    label: Translation.tr("Used:"),
                    value: root.formatKB(ResourceUsage.memoryUsed)
                },
                {
                    icon: "check_circle",
                    label: Translation.tr("Free:"),
                    value: root.formatKB(ResourceUsage.memoryFree)
                },
                {
                    icon: "empty_dashboard",
                    label: Translation.tr("Total:"),
                    value: root.formatKB(ResourceUsage.memoryTotal)
                }
            ]
        },
        {
            icon: "swap_horiz",
            name: Translation.tr("Swap"),
            history: ResourceUsage.swapUsageHistory,
            maxAvailableString: ResourceUsage.maxAvailableSwapString,
            available: true,
              extraProperties: [
                {
                    icon: "clock_loader_60",
                    label: Translation.tr("Used:"),
                    value: root.formatKB(ResourceUsage.swapUsed)
                },
                {
                    icon: "check_circle",
                    label: Translation.tr("Free:"),
                    value: root.formatKB(ResourceUsage.swapFree)
                },
                {
                    icon: "empty_dashboard",
                    label: Translation.tr("Total:"),
                    value: root.formatKB(ResourceUsage.swapTotal)
                }
            ]
            
        },
        {
            icon: "empty_dashboard",
            name: Translation.tr("iGPU"),
            history: GpuUsage.iGpuUsageHistory,
            maxAvailableString: GpuUsage.maxAvailableIGpuString,
            available: GpuUsage.iGpuAvailable,
              extraProperties: [
                {
                    icon: "bolt",
                    label: Translation.tr("Load:"),
                    value: (GpuUsage.iGpuUsage > 0.8 ? Translation.tr("High") : GpuUsage.iGpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(GpuUsage.iGpuUsage * 100)}%)`
                },
                {
                    icon: "clock_loader_60",
                    label: Translation.tr("VRAM:"),
                    value: ` ${Math.round(GpuUsage.iGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.iGpuVramTotalGB * 10) / 10} GB`
                },
                {
                    icon: "thermometer",
                    label: Translation.tr("Temp:"),
                    value: `${GpuUsage.iGpuTempemperature} °C`
                }
            ]
        },
        {
            icon: "empty_dashboard",
            name: Translation.tr("dGPU"),
            history: GpuUsage.dGpuUsageHistory,
            maxAvailableString: GpuUsage.maxAvailabledDGpuString,
            available: GpuUsage.dGpuAvailable,
              extraProperties: [
                {
                    icon: "bolt",
                    label: Translation.tr("Load:"),
                    value: (GpuUsage.dGpuUsage > 0.8 ? Translation.tr("High") : GpuUsage.dGpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(GpuUsage.dGpuUsage * 100)}%)`
                },
                {
                    icon: "clock_loader_60",
                    label: Translation.tr("VRAM:"),
                    value: ` ${Math.round(GpuUsage.dGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.dGpuVramTotalGB * 10) / 10} GB`
                },
                {
                    icon: "thermometer",
                    label: Translation.tr("Temp:"),
                    value: `${GpuUsage.dGpuTempemperature} °C`
                  },

                 {
                    icon: "air",
                    label: Translation.tr("Fan:"),
                    value: `${GpuUsage.dGpuFanUsage} %`
                  },

                 {
                    icon: "power",
                    label: Translation.tr("Power:"),
                    value: `${GpuUsage.dGpuPower} W / ${GpuUsage.dGpuPowerLimit} W`

                }
            ]
        }
    ].filter(r => r.available) 


    contentItem: Rectangle {
        id: contentItem
        anchors.centerIn: parent
        color: Appearance.m3colors.m3surfaceContainer
        radius: root.contentRadius
        property real padding: 4
        implicitWidth: 350
        implicitHeight: 300
        // implicitHeight: contentColumn.implicitHeight + padding * 2
        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: parent.padding
            }
            spacing: 8

            SecondaryTabBar {
                id: tabBar

                currentIndex: Persistent.states.overlay.resources.tabIndex
                onCurrentIndexChanged: {
                    Persistent.states.overlay.resources.tabIndex = tabBar.currentIndex;
                }

                Repeater {
                    model: root.resources.length
                    delegate: SecondaryTabButton {
                        required property int index
                        property var modelData: root.resources[index]
                        buttonIcon: modelData.icon
                        buttonText: modelData.name
                    }
                }
            }

            ResourceSummary {
                Layout.margins: 8
                history: root.resources[tabBar.currentIndex]?.history ?? []
                maxAvailableString: root.resources[tabBar.currentIndex]?.maxAvailableString ?? "--"
              }

        ColumnLayout {
             spacing: 4
             Repeater {
            model:  root.resources[tabBar.currentIndex]?.extraProperties.length ?? 0 
            delegate: RowLayout {
                required property int index 
              property var modelData: root.resources[tabBar.currentIndex]?.extraProperties[index] 
                
                spacing: 4
                MaterialSymbol {
                    text: modelData.icon
                    color: Appearance.colors.colOnSurfaceVariant
                    iconSize: Appearance.font.pixelSize.large
                }
                StyledText {
                    text: modelData.label ?? ""
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    visible: modelData.value !== ""
                    color: Appearance.colors.colOnSurfaceVariant
                    text: modelData.value ?? ""
                }
            }
        }
           
    }
    }

    component ResourceSummary: RowLayout {
        id: resourceSummary
        required property list<real> history
        required property string maxAvailableString

        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12

        ColumnLayout {
            spacing: 2
            StyledText {
                text: (resourceSummary.history[resourceSummary.history.length - 1] * 100).toFixed(1) + "%"
                font {
                    family: Appearance.font.family.numbers
                    variableAxes: Appearance.font.variableAxes.numbers
                    pixelSize: Appearance.font.pixelSize.huge
                }
            }
            StyledText {
                text: Translation.tr("of %1").arg(resourceSummary.maxAvailableString)
                font {
                    // family: Appearance.font.family.numbers
                    // variableAxes: Appearance.font.variableAxes.numbers
                    pixelSize: Appearance.font.pixelSize.smallie
                }
                color: Appearance.colors.colSubtext
            }
            Item {
                Layout.fillHeight: true
            }
        }
        Rectangle {
            id: graphBg
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.small
            color: Appearance.colors.colSecondaryContainer
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: graphBg.width
                    height: graphBg.height
                    radius: graphBg.radius
                }
            }
            Graph {
                anchors.fill: parent
                values: root.resources[tabBar.currentIndex]?.history ?? []
                points: ResourceUsage.historyLength
                alignment: Graph.Alignment.Right
            }
          }


        }
      }
       
}
