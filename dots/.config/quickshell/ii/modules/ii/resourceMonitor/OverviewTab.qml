import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.resourceMonitor
import "../../common/models" as Models
import "../../common/functions/ResourceMonitorUtils.js" as Utils

StyledFlickable {
    id: root
    contentHeight: overviewContent.implicitHeight + 20

    Models.ResourceBackend {
        id: backend
        active: root.visible
        selectedGpuIndex: root.selectedGpuIndex
    }

    // Data properties
    property real gpuUsage: backend.gpuUsage
    property real gpuMemoryUsed: backend.gpuMemoryUsed
    property real gpuMemoryTotal: backend.gpuMemoryTotal
    property string gpuName: backend.gpuName
    
    property real diskUsed: backend.diskUsed
    property real diskTotal: backend.diskTotal
    
    property real networkDownSpeed: backend.networkDownSpeed
    property real networkUpSpeed: backend.networkUpSpeed
    
    property int cpuCores: backend.cpuCores
    property string cpuName: backend.cpuName

    // GPU properties
    property var gpuList: backend.gpuList
    property int selectedGpuIndex: 0
    
    readonly property int historyLength: 60
    property list<real> cpuHistory: []
    property list<real> memHistory: []
    property list<real> gpuHistory: []
    property list<real> netHistory: []
    property real maxNetSpeed: 1024 * 1024

    // Update timer
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.cpuHistory = [...root.cpuHistory.slice(-(root.historyLength - 1)), ResourceUsage.cpuUsage]
            root.memHistory = [...root.memHistory.slice(-(root.historyLength - 1)), ResourceUsage.memoryUsed / ResourceUsage.memoryTotal]
            root.gpuHistory = [...root.gpuHistory.slice(-(root.historyLength - 1)), root.gpuUsage / 100]
            
            var currentNetSpeed = root.networkDownSpeed + root.networkUpSpeed
            if (currentNetSpeed > root.maxNetSpeed) root.maxNetSpeed = currentNetSpeed
            var netUsage = root.maxNetSpeed > 0 ? currentNetSpeed / root.maxNetSpeed : 0
            root.netHistory = [...root.netHistory.slice(-(root.historyLength - 1)), Math.min(1, netUsage)]
        }
    }

    ColumnLayout {
        id: overviewContent
        width: parent.width
        spacing: 12

        // Row 1: CPU and Memory
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ResourceCard {
                Layout.fillWidth: true
                title: "CPU"
                icon: "memory"
                value: (ResourceUsage.cpuUsage * 100).toFixed(1) + "%"
                progress: ResourceUsage.cpuUsage
                subtitle: root.cpuName + " (" + root.cpuCores + " cores)"
                history: root.cpuHistory
                progressColor: Appearance.m3colors.m3primary
            }

            ResourceCard {
                Layout.fillWidth: true
                title: Translation.tr("Memory")
                icon: "memory_alt"
                value: Utils.formatBytes(ResourceUsage.memoryUsed)
                progress: ResourceUsage.memoryUsed / ResourceUsage.memoryTotal
                subtitle: Utils.formatBytes(ResourceUsage.memoryTotal) + " total"
                history: root.memHistory
                progressColor: Appearance.m3colors.m3primary
            }
        }

        // Row 2: GPU and Swap
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ResourceCard {
                Layout.fillWidth: true
                title: "GPU"
                icon: "developer_board"
                value: root.gpuUsage.toFixed(1) + "%"
                progress: root.gpuUsage / 100
                subtitle: root.gpuName
                history: root.gpuHistory
                progressColor: Appearance.m3colors.m3primary
                
                pills: {
                    var list = []
                    for(var i=0; i<root.gpuList.length; i++) list.push("GPU " + i)
                    return list
                }
                activePillIndex: root.selectedGpuIndex
                onPillClicked: index => root.selectedGpuIndex = index
            }

            ResourceCard {
                Layout.fillWidth: true
                title: "Swap"
                icon: "swap_horiz"
                value: (ResourceUsage.swapUsed / (1024 * 1024)).toFixed(2) + " GB"
                progress: ResourceUsage.swapTotal > 0 ? ResourceUsage.swapUsed / ResourceUsage.swapTotal : 0
                subtitle: ResourceUsage.swapTotal > 0 ? (ResourceUsage.swapTotal / (1024 * 1024)).toFixed(2) + " GB total" : "Not configured"
                progressColor: Appearance.m3colors.m3primary
            }
        }

        // Row 3: Disk and Network
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ResourceCard {
                Layout.fillWidth: true
                title: Translation.tr("Disk") + " (/)"
                icon: "hard_drive"
                value: Utils.formatBytes(root.diskUsed)
                progress: root.diskUsed / root.diskTotal
                subtitle: Utils.formatBytes(root.diskTotal) + " total"
                progressColor: Appearance.m3colors.m3primary
                showGraph: false
            }

            ResourceCard {
                Layout.fillWidth: true
                title: Translation.tr("Network")
                icon: "wifi"
                value: "↓ " + Utils.formatSpeed(root.networkDownSpeed)
                progress: root.maxNetSpeed > 0 ? (root.networkDownSpeed + root.networkUpSpeed) / root.maxNetSpeed : 0
                subtitle: "↑ " + Utils.formatSpeed(root.networkUpSpeed)
                history: root.netHistory
                progressColor: Appearance.m3colors.m3primary
                showProgress: true
                showGraph: true
            }
        }
    }
}
