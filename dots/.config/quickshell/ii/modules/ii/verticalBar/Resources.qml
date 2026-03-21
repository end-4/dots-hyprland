import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    property bool alwaysShowAllResources: false
    readonly property bool hasActiveMedia: (MprisController.activePlayer?.trackTitle?.length ?? 0) > 0
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ColumnLayout {
        id: columnLayout
        spacing: 10
        anchors.fill: parent

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            shown: (Config.options?.bar?.resources?.showRam ?? true)
            warningThreshold: Config.options?.bar?.resources?.memoryWarningThreshold ?? 95
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options?.bar?.resources?.showSwap ?? true) && (!root.hasActiveMedia || root.alwaysShowAllResources)
            warningThreshold: Config.options?.bar?.resources?.swapWarningThreshold ?? 85
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: (Config.options?.bar?.resources?.showCpu ?? true)
            warningThreshold: Config.options?.bar?.resources?.cpuWarningThreshold ?? 90
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "storage"
            percentage: ResourceUsage.diskUsedPercentage
            shown: (Config.options?.bar?.resources?.showDisk ?? true) && (!root.hasActiveMedia || root.alwaysShowAllResources)
            warningThreshold: 90
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "videogame_asset"
            percentage: ResourceUsage.gpuUsage
            shown: (Config.options?.bar?.resources?.showGpu ?? true) && ResourceUsage.gpuAvailable && (!root.hasActiveMedia || root.alwaysShowAllResources)
            warningThreshold: Config.options?.bar?.resources?.gpuWarningThreshold ?? 90
        }

    }

    Bar.ResourcesPopup {
        hoverTarget: root
    }
}
