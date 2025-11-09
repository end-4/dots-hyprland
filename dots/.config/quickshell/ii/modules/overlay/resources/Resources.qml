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
    id: root
    minimumWidth: 300
    minimumHeight: 300
    function buildIGpuProperties() {
        const cfg = Config.options?.resources?.gpu?.overlay?.iGpu
        let props = []

        if (cfg?.showUsage !== false) {
            props.push({
                icon: "bolt",
                label: Translation.tr("Load:"),
                value:  `${Math.round(GpuUsage.iGpuUsage * 100)} %`
            })
        }

        if (cfg?.showVram !== false) {
            props.push({
                icon: "clock_loader_60",
                label: Translation.tr("VRAM:"),
                value: ` ${Math.round(GpuUsage.iGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.iGpuVramTotalGB * 10) / 10} GB`
            })
        }

        if (cfg?.showTemp !== false) {
            props.push({
                icon: "thermometer",
                label: Translation.tr("Temp:"),
                value: `${GpuUsage.iGpuTemperature} °C`
            })
        }

        return props
    }

    function buildDGpuProperties() {
        const cfg = Config.options?.resources?.gpu?.overlay?.dGpu
        let props = []

        if (cfg?.showUsage !== false) {
            props.push({
                icon: "bolt",
                label: Translation.tr("Load:"),
                value: ` ${Math.round(GpuUsage.dGpuUsage * 100)} %`
            })
        }

        if (cfg?.showVram !== false) {
            props.push({
                icon: "clock_loader_60",
                label: Translation.tr("VRAM:"),
                value: ` ${Math.round(GpuUsage.dGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.dGpuVramTotalGB * 10) / 10} GB`
            })
        }

        if (cfg?.showTemp !== false) {
            props.push({
                icon: "thermometer",
                label: Translation.tr("Temp:"),
                value: `${GpuUsage.dGpuTemperature} °C`
            })
        }

        if (cfg?.showTempJunction === true && GpuUsage.dGpuTempJunction > 0) {
            props.push({
                icon: "thermometer",
                label: Translation.tr("Junction:"),
                value: `${GpuUsage.dGpuTempJunction} °C`
            })
        }

        if (GpuUsage.dGpuTempMem > 0) {
            props.push({
                icon: "thermometer",
                label: Translation.tr("Mem Temp:"),
                value: `${GpuUsage.dGpuTempMem} °C`
            })
        }

        if (cfg?.showFan !== false) {
            props.push({
                icon: "air",
                label: Translation.tr("Fan:"),
                value: GpuUsage.dGpuVendor === "nvidia" ? `${GpuUsage.dGpuFanUsage} %` :
                       GpuUsage.dGpuFanRpm > 0 ? `${GpuUsage.dGpuFanRpm} RPM` : "0"
            })
        }

        if (cfg?.showPower !== false) {
            props.push({
                icon: "power",
                label: Translation.tr("Power:"),
                value: `${GpuUsage.dGpuPower} W / ${GpuUsage.dGpuPowerLimit} W`
            })
        }

        return props
    }


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
                    value: `${Math.round(ResourceUsage.cpuUsage  * 100)}%`
 
                },
                {
                    icon: "planner_review",
                    label: Translation.tr("Freq:"),
                    value: ` ${Math.round(ResourceUsage.cpuFreqency  * 100) /100} GHz`
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
                    value: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)
                },
                {
                    icon: "check_circle",
                    label: Translation.tr("Free:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.memoryFree)
                },
                {
                    icon: "empty_dashboard",
                    label: Translation.tr("Total:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.memoryTotal)
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
                    value: ResourceUsage.kbToGbString(ResourceUsage.swapUsed)
                },
                {
                    icon: "check_circle",
                    label: Translation.tr("Free:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.swapFree)
                },
                {
                    icon: "empty_dashboard",
                    label: Translation.tr("Total:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.swapTotal)
                }
            ]
            
        },
        {
            icon: "empty_dashboard",
            name: Translation.tr("IGPU"),
            history: (Config.options?.resources?.enableGpu !== false) ? GpuUsage.iGpuUsageHistory : [],
            maxAvailableString: GpuUsage.maxAvailableIGpuString,
            available: (Config.options?.resources?.enableGpu === false && Config.options?.resources?.gpu?.overlay?.showIGpu !== false) ||
                       (GpuUsage.iGpuAvailable && (Config.options?.resources?.gpu?.overlay?.showIGpu !== false)),
            disabled: Config.options?.resources?.enableGpu === false,
            extraProperties: (Config.options?.resources?.enableGpu === false) ?
                [{icon: "block", label: "", value: Translation.tr("GPU monitoring is disabled")}] :
                root.buildIGpuProperties()
        },
        {
            icon: "empty_dashboard",
            name: Translation.tr("DGPU"),
            history: (Config.options?.resources?.enableGpu !== false) ? GpuUsage.dGpuUsageHistory : [],
            maxAvailableString: GpuUsage.maxAvailableDGpuString,
            available: (Config.options?.resources?.enableGpu === false && Config.options?.resources?.gpu?.overlay?.showDGpu !== false) ||
                       (GpuUsage.dGpuAvailable && (Config.options?.resources?.gpu?.overlay?.showDGpu !== false)),
            disabled: Config.options?.resources?.enableGpu === false,
            extraProperties: (Config.options?.resources?.enableGpu === false) ?
                [{icon: "block", label: "", value: Translation.tr("GPU monitoring is disabled")}] :
                root.buildDGpuProperties()
        }
    ].filter(r => r.available) 

    contentItem: Rectangle {
        id: contentItem
        anchors.fill: parent
        color: Appearance.m3colors.m3surfaceContainer
        radius: root.contentRadius
        property real padding: 4
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

            ExtraInfo {
                Layout.margins: 8
                Layout.topMargin: 0
                extraProperties: root.resources[tabBar.currentIndex]?.extraProperties ?? []
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
                font.pixelSize: Appearance.font.pixelSize.smallie
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

    component ExtraInfo: ColumnLayout {
        id: extraInfo
        required property list<var> extraProperties
        visible: extraProperties.length > 0
        spacing: 4

        Repeater {
            model: ScriptModel {
                values: extraInfo.extraProperties
                objectProp: "icon" // A prop that doesn't change
            }
            delegate: RowLayout {
                id: extraInfoRow
                required property var modelData

                spacing: 4
                MaterialSymbol {
                    text: extraInfoRow.modelData.icon
                    color: Appearance.colors.colOnSurfaceVariant
                    iconSize: Appearance.font.pixelSize.large
                }
                StyledText {
                    text: extraInfoRow.modelData.label ?? ""
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    visible: extraInfoRow.modelData.value !== ""
                    color: Appearance.colors.colOnSurfaceVariant
                    text: extraInfoRow.modelData.value ?? ""
                }
            }
        }
    }
}
