import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool alwaysShowAllResources: false
    implicitWidth: rowLayout.visible ? rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin : 0
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: true

    Behavior on implicitWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    RowLayout {
        id: rowLayout

        visible: memoryResource.shown || swapResource.shown || cpuResource.shown
    
        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            id: memoryResource
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            shown: Config.options.bar.resources.items.find(i => i.type === "memory").collapse && (MprisController.activePlayer?.trackTitle?.length > 0) ? false : Config.options.bar.resources.items.find(i => i.type === "memory").visible 
            detailed: Config.options.bar.resources.style === "detailed"
        }

        Resource {
            id: swapResource
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
            shown: Config.options.bar.resources.items.find(i => i.type === "swap").collapse && (MprisController.activePlayer?.trackTitle?.length > 0) ? false : Config.options.bar.resources.items.find(i => i.type === "swap").visible
            detailed: Config.options.bar.resources.style === "detailed"
        }

        Resource {
            id: cpuResource
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            shown: Config.options.bar.resources.items.find(i => i.type === "cpu").collapse && (MprisController.activePlayer?.trackTitle?.length > 0) ? false : Config.options.bar.resources.items.find(i => i.type === "cpu").visible
            detailed: Config.options.bar.resources.style === "detailed"
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
