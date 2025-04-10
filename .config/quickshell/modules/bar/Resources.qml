import "../common"
import "../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 32
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.small

    RowLayout {
        id: rowLayout

        spacing: 4
        anchors.centerIn: parent

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
        }
        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
        }
        Resource {
            iconName: "settings_slow_motion"
            percentage: ResourceUsage.cpuUsage
        }

    }

}
