import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage

            tooltipHeaderIcon: "memory"
            tooltipHeaderText: Translation.tr("Memory usage")
            tooltipData: [
                { icon: "clock_loader_60", label: Translation.tr("Used:"), value: formatKB(ResourceUsage.memoryUsed) },
                { icon: "check_circle", label: Translation.tr("Free:"), value: formatKB(ResourceUsage.memoryFree) },
                { icon: "empty_dashboard", label: Translation.tr("Total:"), value: formatKB(ResourceUsage.memoryTotal) },
            ]
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) || 
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0

            tooltipHeaderIcon: "swap_horiz"
            tooltipHeaderText: Translation.tr("Swap usage")
            tooltipData: ResourceUsage.swapTotal > 0 ? [
                { icon: "clock_loader_60", label: Translation.tr("Used:"), value: formatKB(ResourceUsage.swapUsed) },
                { icon: "check_circle", label: Translation.tr("Free:"), value: formatKB(ResourceUsage.swapFree) },
                { icon: "empty_dashboard", label: Translation.tr("Total:"), value: formatKB(ResourceUsage.swapTotal) },
            ] : [
                { icon: "swap_horiz", label: Translation.tr("Swap:"), value: Translation.tr("Not configured") }
            ]
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0

            tooltipHeaderIcon: "planner_review"
            tooltipHeaderText: Translation.tr("CPU usage")
            tooltipData: [
                { icon: "bolt", label: Translation.tr("Load:"), value: (ResourceUsage.cpuUsage > 0.8 ?
                    Translation.tr("High") :
                    ResourceUsage.cpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low"))
                    + ` (${Math.round(ResourceUsage.cpuUsage * 100)}%)`
                }
            ]
        }

    }

}
