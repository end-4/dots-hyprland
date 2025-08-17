import qs.services
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
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
        }

    }

    Bar.ResourcesPopup {
        hoverTarget: root
    }
}
