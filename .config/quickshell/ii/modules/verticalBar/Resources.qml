import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import "../bar" as Bar

MouseArea {
    id: root
    property bool alwaysShowAllResources: false
    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    hoverEnabled: true

    ColumnLayout {
        id: columnLayout
        spacing: 10
        anchors.fill: parent

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

    }

    Bar.ResourcesPopup {
        hoverTarget: root
    }
}
