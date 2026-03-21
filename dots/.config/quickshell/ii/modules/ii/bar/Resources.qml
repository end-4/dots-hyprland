import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    readonly property bool hasActiveMedia: (MprisController.activePlayer?.trackTitle?.length ?? 0) > 0
    clip: true
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            shown: (Config.options?.bar?.resources?.showRam ?? true)
            warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options?.bar?.resources?.showSwap ?? true) && (!root.hasActiveMedia || root.alwaysShowAllResources)
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options?.bar?.resources?.swapWarningThreshold ?? 85
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: (Config.options?.bar?.resources?.showCpu ?? true)
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
        }

        Resource {
            iconName: "storage"
            percentage: ResourceUsage.diskUsedPercentage
            shown: (Config.options?.bar?.resources?.showDisk ?? true) && (!root.hasActiveMedia || root.alwaysShowAllResources)
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: 90
        }

        Resource {
            iconName: "videogame_asset"
            percentage: ResourceUsage.gpuUsage
            shown: (Config.options?.bar?.resources?.showGpu ?? true) && ResourceUsage.gpuAvailable && (!root.hasActiveMedia || root.alwaysShowAllResources)
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
