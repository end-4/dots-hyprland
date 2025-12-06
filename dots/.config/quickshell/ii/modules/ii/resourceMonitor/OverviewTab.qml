import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.resourceMonitor
import qs.modules.common.models as Models
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
    property real diskActiveTime: backend.diskActiveTime
    
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
    property list<real> diskHistory: []
    property real maxNetSpeed: 1024 * 1024

    // Update timer
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.cpuHistory = [...root.cpuHistory.slice(-(root.historyLength - 1)), backend.cpuUsage]
            root.memHistory = [...root.memHistory.slice(-(root.historyLength - 1)), backend.memoryUsed / backend.memoryTotal]
            root.gpuHistory = [...root.gpuHistory.slice(-(root.historyLength - 1)), root.gpuUsage / 100]
            root.diskHistory = [...root.diskHistory.slice(-(root.historyLength - 1)), root.diskActiveTime]
            
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
                value: (backend.cpuUsage * 100).toFixed(1) + "%"
                progress: backend.cpuUsage
                subtitle: root.cpuName + " (" + root.cpuCores + " cores)"
                history: root.cpuHistory
                progressColor: Appearance.m3colors.m3primary
            }

            ResourceCard {
                Layout.fillWidth: true
                title: Translation.tr("Memory")
                icon: "memory_alt"
                value: Utils.formatBytes(backend.memoryUsed)
                progress: backend.memoryUsed / backend.memoryTotal
                subtitle: Utils.formatBytes(backend.memoryTotal) + " total"
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
                    for(var i=0; i<root.gpuList.length; i++) {
                        var gpu = root.gpuList[i]
                        var name = "GPU " + i
                        if (gpu.type === "nvidia") name = "NVIDIA"
                        else if (gpu.type === "intel") name = "Intel"
                        else if (gpu.type === "amd") name = "AMD"
                        
                        // Check if we have multiple of the same type to append index
                        var count = 0
                        for(var j=0; j<root.gpuList.length; j++) {
                            if (root.gpuList[j].type === gpu.type) count++
                        }
                        if (count > 1) name += " " + i
                        
                        list.push(name)
                    }
                    return list
                }
                activePillIndex: root.selectedGpuIndex
                onPillClicked: index => root.selectedGpuIndex = index
            }

            ResourceCard {
                Layout.fillWidth: true
                title: "Swap"
                icon: "swap_horiz"
                value: (backend.swapUsed / (1024 * 1024 * 1024)).toFixed(2) + " GB"
                progress: backend.swapTotal > 0 ? backend.swapUsed / backend.swapTotal : 0
                subtitle: backend.swapTotal > 0 ? (backend.swapTotal / (1024 * 1024 * 1024)).toFixed(2) + " GB total" : "Not configured"
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
                value: ((root.diskUsed / root.diskTotal) * 100).toFixed(0) + "%"
                progress: root.diskUsed / root.diskTotal
                subtitle: Utils.formatBytes(root.diskUsed) + " / " + Utils.formatBytes(root.diskTotal)
                history: root.diskHistory
                progressColor: Appearance.m3colors.m3primary
                showGraph: true
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
