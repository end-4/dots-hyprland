import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options.bar.resources.alwaysShowSwap && percentage > 0) || 
                (MprisController.activePlayer?.trackTitle == null) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: Config.options.bar.resources.alwaysShowCpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources
            Layout.leftMargin: shown ? 6 : 0
          }

         Resource {
            iconName: "empty_dashboard"
            percentage: (Config.options.bar.resources.gpuLayout == 0 || Config.options.bar.resources.gpuLayout ==2) ? ResourceUsage.dGpuUsage : ResourceUsage.iGpuUsage
            shown: (Config.options.bar.resources.alwaysShowGpu || 
                !(MprisController.activePlayer?.trackTitle?.length > 0) ||
                root.alwaysShowAllResources) && (  (ResourceUsage.dGpuAvailable &&  (Config.options.bar.resources.gpuLayout == 0 || Config.options.bar.resources.gpuLayout ==2) ) 
                ||  (ResourceUsage.iGpuAvailable &&  (Config.options.bar.resources.gpuLayout == 1)  )) 
            Layout.leftMargin: shown ? 6 : 0
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
