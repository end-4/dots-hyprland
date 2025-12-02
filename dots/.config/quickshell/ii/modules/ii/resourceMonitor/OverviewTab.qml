import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.resourceMonitor

StyledFlickable {
    id: root
    contentHeight: overviewContent.implicitHeight + 20

    // Data properties
    property real gpuUsage: 0
    property real gpuMemoryUsed: 0
    property real gpuMemoryTotal: 1
    property string gpuName: "Detecting..."
    
    property real diskUsed: 0
    property real diskTotal: 1
    
    property real networkDownSpeed: 0
    property real networkUpSpeed: 0
    property real previousRxBytes: 0
    property real previousTxBytes: 0
    
    property int cpuCores: 0
    property string cpuName: "Detecting..."

    // GPU properties
    property var gpuList: []
    property int selectedGpuIndex: 0
    
    readonly property int historyLength: 60
    property list<real> cpuHistory: []
    property list<real> memHistory: []
    property list<real> gpuHistory: []
    property list<real> netHistory: []
    property real maxNetSpeed: 1024 * 1024  // Track max speed for scaling graph

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes.toFixed(0) + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + " MB"
        return (bytes / (1024 * 1024 * 1024)).toFixed(2) + " GB"
    }

    function formatSpeed(bytesPerSec) {
        if (bytesPerSec < 1024) return bytesPerSec.toFixed(0) + " B/s"
        if (bytesPerSec < 1024 * 1024) return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        return (bytesPerSec / (1024 * 1024)).toFixed(2) + " MB/s"
    }

    // CPU cores detection
    Process {
        id: cpuCoresProc
        command: ["nproc"]
        running: true
        stdout: SplitParser {
            onRead: data => root.cpuCores = parseInt(data.trim()) || 0
        }
    }

    // CPU name detection
    Process {
        id: cpuNameProc
        command: ["bash", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //'"]
        running: true
        stdout: SplitParser {
            onRead: data => root.cpuName = data.trim() || "Unknown CPU"
        }
    }

    // GPU Discovery
    property string gpuDiscoveryBuffer: ""
    Process {
        id: gpuDiscovery
        command: ["bash", "-c", "lspci -mm | grep -E 'VGA|3D|Display'"]
        running: true
        stdout: SplitParser {
            onRead: data => root.gpuDiscoveryBuffer += data + "\n"
        }
        onExited: (exitCode, exitStatus) => {
            var lines = root.gpuDiscoveryBuffer.trim().split("\n")
            var gpus = []
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i]
                if (!line) continue
                
                // Parse lspci -mm output
                // Format: Slot "Class" "Vendor" "Device" ...
                // Example: 00:02.0 "Display controller" "Intel Corporation" "Raptor Lake-P [UHD Graphics]" ...
                var parts = line.split('"')
                if (parts.length >= 6) {
                    var busId = parts[0].trim()
                    var vendor = parts[3]
                    var device = parts[5]
                    var type = "other"
                    
                    if (vendor.toLowerCase().includes("nvidia")) type = "nvidia"
                    else if (vendor.toLowerCase().includes("intel")) type = "intel"
                    else if (vendor.toLowerCase().includes("amd") || vendor.toLowerCase().includes("ati")) type = "amd"
                    
                    gpus.push({
                        name: device,
                        vendor: vendor,
                        type: type,
                        busId: busId,
                        index: gpus.length
                    })
                }
            }
            
            // Sort GPUs: NVIDIA first, then others
            gpus.sort((a, b) => {
                if (a.type === "nvidia" && b.type !== "nvidia") return -1
                if (a.type !== "nvidia" && b.type === "nvidia") return 1
                return 0
            })
            
            // Reassign indices after sort
            for (var j = 0; j < gpus.length; j++) {
                gpus[j].index = j
            }
            
            root.gpuList = gpus
            if (gpus.length > 0) {
                root.selectedGpuIndex = 0
                gpuProc.updateCommand()
            }
        }
    }

    onSelectedGpuIndexChanged: gpuProc.updateCommand()

    // GPU monitoring
    Process {
        id: gpuProc
        command: [] 
        
        function updateCommand() {
            if (root.gpuList.length === 0) return
            var gpu = root.gpuList[root.selectedGpuIndex]
            
            if (gpu.type === "nvidia") {
                // NVIDIA: Use nvidia-smi with bus ID
                var pciId = "0000:" + gpu.busId
                gpuProc.command = ["bash", "-c", "nvidia-smi --id=" + pciId + " --query-gpu=utilization.gpu,memory.used,memory.total,name --format=csv,noheader,nounits 2>/dev/null || echo '0,0,1,' + '" + gpu.name + "'"]
            } else {
                // Generic: Try /sys/class/drm
                var pciId = "0000:" + gpu.busId
                var cmd = "pci_path=\"/sys/bus/pci/devices/" + pciId + "/drm\"; " +
                          "card=$(ls $pci_path 2>/dev/null | grep -E '^card[0-9]+$' | head -n1); " +
                          "usage=0; mem_used=0; mem_total=1; " +
                          "if [ ! -z \"$card\" ]; then " +
                              "if [ -f \"$pci_path/$card/device/gpu_busy_percent\" ]; then " +
                                  "usage=$(cat \"$pci_path/$card/device/gpu_busy_percent\"); " +
                              "fi; " +
                          "fi; " +
                          "echo \"$usage,$mem_used,$mem_total," + gpu.name + "\""
                gpuProc.command = ["bash", "-c", cmd]
            }
        }

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(",")
                if (parts.length >= 4) {
                    root.gpuUsage = parseFloat(parts[0]) || 0
                    root.gpuMemoryUsed = parseFloat(parts[1]) || 0
                    root.gpuMemoryTotal = parseFloat(parts[2]) || 1
                    root.gpuName = parts[3] || "Unknown"
                }
            }
        }
    }

    // Disk monitoring
    Process {
        id: diskProc
        command: ["bash", "-c", "df -B1 / | tail -1 | awk '{print $3,$2}'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(" ")
                if (parts.length >= 2) {
                    root.diskUsed = parseFloat(parts[0]) || 0
                    root.diskTotal = parseFloat(parts[1]) || 1
                }
            }
        }
    }

    // Network monitoring
    Process {
        id: netProc
        command: ["bash", "-c", "cat /proc/net/dev | tail -n +3 | grep -v lo: | awk '{rx+=$2; tx+=$10} END {print rx, tx}'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(" ")
                if (parts.length >= 2) {
                    const totalRx = parseInt(parts[0]) || 0
                    const totalTx = parseInt(parts[1]) || 0
                    if (root.previousRxBytes > 0) {
                        root.networkDownSpeed = totalRx - root.previousRxBytes
                        root.networkUpSpeed = totalTx - root.previousTxBytes
                    }
                    root.previousRxBytes = totalRx
                    root.previousTxBytes = totalTx
                }
            }
        }
    }

    // Update timer
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gpuProc.running = true
            diskProc.running = true
            netProc.running = true
            
            root.cpuHistory = [...root.cpuHistory.slice(-(root.historyLength - 1)), ResourceUsage.cpuUsage]
            root.memHistory = [...root.memHistory.slice(-(root.historyLength - 1)), ResourceUsage.memoryUsed / ResourceUsage.memoryTotal]
            root.gpuHistory = [...root.gpuHistory.slice(-(root.historyLength - 1)), root.gpuUsage / 100]
            
            // Track network speed history (normalized to max observed speed)
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
                value: root.formatBytes(ResourceUsage.memoryUsed)
                progress: ResourceUsage.memoryUsed / ResourceUsage.memoryTotal
                subtitle: root.formatBytes(ResourceUsage.memoryTotal) + " total"
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
                value: root.formatBytes(root.diskUsed)
                progress: root.diskUsed / root.diskTotal
                subtitle: root.formatBytes(root.diskTotal) + " total"
                progressColor: Appearance.m3colors.m3primary
                showGraph: false
            }

            ResourceCard {
                Layout.fillWidth: true
                title: Translation.tr("Network")
                icon: "wifi"
                value: "↓ " + root.formatSpeed(root.networkDownSpeed)
                progress: root.maxNetSpeed > 0 ? (root.networkDownSpeed + root.networkUpSpeed) / root.maxNetSpeed : 0
                subtitle: "↑ " + root.formatSpeed(root.networkUpSpeed)
                history: root.netHistory
                progressColor: Appearance.m3colors.m3primary
                showProgress: true
                showGraph: true
            }
        }
    }
}
