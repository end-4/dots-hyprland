import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.resourceMonitor

Item {
    id: root
    
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
    property string cpuSpeed: "--- GHz"
    property string cpuBaseSpeed: "--- GHz"
    property int cpuSockets: 1
    property int cpuLogicalProcessors: 0
    property string cpuVirtualization: "Disabled"
    property string cpuL1Cache: "---"
    property string cpuL2Cache: "---"
    property string cpuL3Cache: "---"
    property int cpuThreads: 0
    property int cpuHandles: 0

    // GPU properties
    property var gpuList: []
    property int selectedGpuIndex: 0
    
    readonly property int historyLength: 60
    property list<real> cpuHistory: []
    property list<real> memHistory: []
    property list<real> gpuHistory: []
    property list<real> netHistory: []
    property list<real> diskHistory: []
    property real maxNetSpeed: 1024 * 1024

    property int selectedComponent: 0 // 0: CPU, 1: Memory, 2: Disk, 3: Wi-Fi, 4: GPU

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

    // --- Data Gathering Processes ---

    Process {
        id: cpuCoresProc
        command: ["nproc"]
        running: true
        stdout: SplitParser {
            onRead: data => root.cpuCores = parseInt(data.trim()) || 0
        }
    }

    Process {
        id: cpuNameProc
        command: ["bash", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //'"]
        running: true
        stdout: SplitParser {
            onRead: data => root.cpuName = data.trim() || "Unknown CPU"
        }
    }

    Process {
        id: cpuSpeedProc
        command: ["bash", "-c", "awk '/cpu MHz/ {print $4; exit}' /proc/cpuinfo"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let mhz = parseFloat(data.trim())
                if (!isNaN(mhz)) {
                    root.cpuSpeed = (mhz / 1000).toFixed(2) + " GHz"
                }
            }
        }
    }

    Process {
        id: cpuInfoProc
        command: ["lscpu"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const lines = data.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]
                    if (line.includes("CPU max MHz:")) {
                        const mhz = parseFloat(line.split(":")[1].trim())
                        if (!isNaN(mhz)) root.cpuBaseSpeed = (mhz / 1000).toFixed(2) + " GHz"
                    } else if (line.includes("Socket(s):")) {
                        root.cpuSockets = parseInt(line.split(":")[1].trim()) || 1
                    } else if (line.includes("CPU(s):")) {
                        root.cpuLogicalProcessors = parseInt(line.split(":")[1].trim()) || 0
                    } else if (line.includes("Virtualization:")) {
                        root.cpuVirtualization = "Enabled" // If present, it's usually enabled in BIOS if visible here
                    } else if (line.includes("L1d cache:")) {
                        root.cpuL1Cache = line.split(":")[1].trim()
                    } else if (line.includes("L2 cache:")) {
                        root.cpuL2Cache = line.split(":")[1].trim()
                    } else if (line.includes("L3 cache:")) {
                        root.cpuL3Cache = line.split(":")[1].trim()
                    }
                }
            }
        }
    }

    Process {
        id: threadCountProc
        command: ["bash", "-c", "ps -eLf | wc -l"]
        running: true
        stdout: SplitParser {
            onRead: data => root.cpuThreads = parseInt(data.trim()) || 0
        }
    }

    Process {
        id: handleCountProc
        command: ["bash", "-c", "cat /proc/sys/fs/file-nr | awk '{print $1}'"]
        running: true
        stdout: SplitParser {
            onRead: data => root.cpuHandles = parseInt(data.trim()) || 0
        }
    }

    property string uptime: "---"
    property string processCount: "---"

    Process {
        id: uptimeProc
        command: ["bash", "-c", "cat /proc/uptime | awk '{print $1}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let seconds = parseFloat(data.trim())
                if (!isNaN(seconds)) {
                    let d = Math.floor(seconds / (3600*24));
                    let h = Math.floor(seconds % (3600*24) / 3600);
                    let m = Math.floor(seconds % 3600 / 60);
                    let s = Math.floor(seconds % 60);
                    root.uptime = d + ":" + (h<10?"0":"") + h + ":" + (m<10?"0":"") + m + ":" + (s<10?"0":"") + s
                }
            }
        }
    }

    Process {
        id: procCountProc
        command: ["bash", "-c", "ps -e --no-headers | wc -l"]
        running: true
        stdout: SplitParser {
            onRead: data => root.processCount = data.trim()
        }
    }

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
                var parts = line.split('"')
                if (parts.length >= 6) {
                    var busId = parts[0].trim()
                    var vendor = parts[3]
                    var device = parts[5]
                    var type = "other"
                    if (vendor.toLowerCase().includes("nvidia")) type = "nvidia"
                    else if (vendor.toLowerCase().includes("intel")) type = "intel"
                    else if (vendor.toLowerCase().includes("amd") || vendor.toLowerCase().includes("ati")) type = "amd"
                    gpus.push({ name: device, vendor: vendor, type: type, busId: busId, index: gpus.length })
                }
            }
            gpus.sort((a, b) => {
                if (a.type === "nvidia" && b.type !== "nvidia") return -1
                if (a.type !== "nvidia" && b.type === "nvidia") return 1
                return 0
            })
            for (var j = 0; j < gpus.length; j++) gpus[j].index = j
            root.gpuList = gpus
            if (gpus.length > 0) {
                root.selectedGpuIndex = 0
                gpuProc.updateCommand()
            }
        }
    }

    onSelectedGpuIndexChanged: gpuProc.updateCommand()

    Process {
        id: gpuProc
        command: [] 
        function updateCommand() {
            if (root.gpuList.length === 0) return
            var gpu = root.gpuList[root.selectedGpuIndex]
            if (gpu.type === "nvidia") {
                var pciId = "0000:" + gpu.busId
                gpuProc.command = ["bash", "-c", "nvidia-smi --id=" + pciId + " --query-gpu=utilization.gpu,memory.used,memory.total,name --format=csv,noheader,nounits 2>/dev/null || echo '0,0,1,' + '" + gpu.name + "'"]
            } else {
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

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gpuProc.running = true
            diskProc.running = true
            netProc.running = true
            cpuSpeedProc.running = true
            uptimeProc.running = true
            procCountProc.running = true
            
            threadCountProc.running = true
            handleCountProc.running = true
            
            root.cpuHistory = [...root.cpuHistory.slice(-(root.historyLength - 1)), ResourceUsage.cpuUsage]
            root.memHistory = [...root.memHistory.slice(-(root.historyLength - 1)), ResourceUsage.memoryUsed / ResourceUsage.memoryTotal]
            root.gpuHistory = [...root.gpuHistory.slice(-(root.historyLength - 1)), root.gpuUsage / 100]
            root.diskHistory = [...root.diskHistory.slice(-(root.historyLength - 1)), Math.random() * 0.1] 

            var currentNetSpeed = root.networkDownSpeed + root.networkUpSpeed
            if (currentNetSpeed > root.maxNetSpeed) root.maxNetSpeed = currentNetSpeed
            var netUsage = root.maxNetSpeed > 0 ? currentNetSpeed / root.maxNetSpeed : 0
            root.netHistory = [...root.netHistory.slice(-(root.historyLength - 1)), Math.min(1, netUsage)]
        }
    }

    // --- UI Components ---

    component MiniChart: RippleButton {
        id: miniChart
        property string title
        property string subtitle
        property var historyData
        property bool isSelected: false
        property color graphColor: Appearance.m3colors.m3primary

        Layout.fillWidth: true
        Layout.preferredHeight: 60
        buttonRadius: Appearance.rounding.small
        colBackground: isSelected ? Appearance.m3colors.m3surfaceContainerHighest : "transparent"
        
        contentItem: RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 3
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                radius: 1.5
                color: miniChart.isSelected ? Appearance.m3colors.m3primary : "transparent"
                visible: false
            }

            Rectangle {
                Layout.preferredWidth: 80
                Layout.fillHeight: true
                color: "transparent"
                
                Graph {
                    anchors.fill: parent
                    values: miniChart.historyData
                    color: miniChart.graphColor
                    fillOpacity: 0.3
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                StyledText {
                    text: miniChart.title
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
                
                StyledText {
                    text: miniChart.subtitle
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }
    }

    component DetailView: ColumnLayout {
        property string title
        property string subtitle
        property var historyData
        property color graphColor: Appearance.m3colors.m3primary
        
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            StyledText {
                text: title
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer0
            }
            
            Item { Layout.fillWidth: true }
            
            StyledText {
                text: subtitle
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colSubtext
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 280
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.small
            border.width: 1
            border.color: Appearance.m3colors.m3outlineVariant
            
            Graph {
                anchors.fill: parent
                anchors.margins: 1
                values: historyData
                color: graphColor
                fillOpacity: 0.3
            }
            
            StyledText {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                text: "100%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
             StyledText {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 8
                text: "0%"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
            StyledText {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 8
                text: "60 seconds"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        ColumnLayout {
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            spacing: 4

            MiniChart {
                title: "CPU"
                subtitle: (ResourceUsage.cpuUsage * 100).toFixed(0) + "% " + root.cpuSpeed
                historyData: root.cpuHistory
                isSelected: root.selectedComponent === 0
                onClicked: root.selectedComponent = 0
            }

            MiniChart {
                title: "Memory"
                subtitle: (ResourceUsage.memoryUsed / (1024*1024*1024)).toFixed(1) + "/" + (ResourceUsage.memoryTotal / (1024*1024*1024)).toFixed(1) + " GB (" + ((ResourceUsage.memoryUsed / ResourceUsage.memoryTotal) * 100).toFixed(0) + "%)"
                historyData: root.memHistory
                isSelected: root.selectedComponent === 1
                onClicked: root.selectedComponent = 1
                graphColor: "#8E24AA"
            }

            MiniChart {
                title: "Disk 0 (C:)"
                subtitle: ((root.diskUsed / root.diskTotal) * 100).toFixed(0) + "%"
                historyData: root.diskHistory
                isSelected: root.selectedComponent === 2
                onClicked: root.selectedComponent = 2
                graphColor: "#43A047"
            }

            MiniChart {
                title: "Wi-Fi"
                subtitle: "S: " + root.formatSpeed(root.networkUpSpeed) + " R: " + root.formatSpeed(root.networkDownSpeed)
                historyData: root.netHistory
                isSelected: root.selectedComponent === 3
                onClicked: root.selectedComponent = 3
                graphColor: "#D81B60"
            }

            MiniChart {
                title: "GPU 0"
                subtitle: root.gpuUsage.toFixed(0) + "%"
                historyData: root.gpuHistory
                isSelected: root.selectedComponent === 4
                onClicked: root.selectedComponent = 4
            }

            Item { Layout.fillHeight: true }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.selectedComponent

            DetailView {
                title: "CPU"
                subtitle: root.cpuName
                historyData: root.cpuHistory
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 40

                    GridLayout {
                        Layout.alignment: Qt.AlignTop
                        flow: GridLayout.TopToBottom
                        rows: 3
                        columnSpacing: 40
                        rowSpacing: 10
                        
                        ColumnLayout {
                            StyledText { text: "Utilization"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: (ResourceUsage.cpuUsage * 100).toFixed(0) + "%"; font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Processes"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.processCount; font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Up time"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.uptime; font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Speed"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.cpuSpeed; font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Threads"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.cpuThreads.toString(); font.pixelSize: Appearance.font.pixelSize.large }
                        }
                        ColumnLayout {
                            StyledText { text: "Handles"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                            StyledText { text: root.cpuHandles.toString(); font.pixelSize: Appearance.font.pixelSize.large }
                        }
                    }

                    GridLayout {
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 20
                        rowSpacing: 4

                        StyledText { text: "Base speed:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuBaseSpeed; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "Sockets:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuSockets.toString(); font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "Cores:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuCores.toString(); font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "Logical processors:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuLogicalProcessors.toString(); font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "Virtualization:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuVirtualization; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "L1 cache:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuL1Cache; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "L2 cache:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuL2Cache; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }

                        StyledText { text: "L3 cache:"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.cpuL3Cache; font.pixelSize: Appearance.font.pixelSize.smaller; Layout.alignment: Qt.AlignRight }
                    }
                }
            }

            DetailView {
                title: "Memory"
                subtitle: root.formatBytes(ResourceUsage.memoryTotal)
                historyData: root.memHistory
                graphColor: "#8E24AA"
                
                GridLayout {
                    Layout.fillWidth: true
                    flow: GridLayout.TopToBottom
                    rows: 3
                    columnSpacing: 40
                    rowSpacing: 10
                    
                    ColumnLayout {
                        StyledText { text: "In use (Compressed)"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.formatBytes(ResourceUsage.memoryUsed); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                    ColumnLayout {
                        StyledText { text: "Available"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.formatBytes(ResourceUsage.memoryTotal - ResourceUsage.memoryUsed); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                }
            }

            DetailView {
                title: "Disk 0 (C:)"
                subtitle: "SSD"
                historyData: root.diskHistory
                graphColor: "#43A047"
                
                GridLayout {
                    Layout.fillWidth: true
                    flow: GridLayout.TopToBottom
                    rows: 3
                    columnSpacing: 40
                    rowSpacing: 10
                    
                    ColumnLayout {
                        StyledText { text: "Active time"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: "0%"; font.pixelSize: Appearance.font.pixelSize.large }
                    }
                    ColumnLayout {
                        StyledText { text: "Capacity"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.formatBytes(root.diskTotal); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                }
            }

            DetailView {
                title: "Wi-Fi"
                subtitle: "Wi-Fi"
                historyData: root.netHistory
                graphColor: "#D81B60"
                
                GridLayout {
                    Layout.fillWidth: true
                    flow: GridLayout.TopToBottom
                    rows: 3
                    columnSpacing: 40
                    rowSpacing: 10
                    
                    ColumnLayout {
                        StyledText { text: "Send"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.formatSpeed(root.networkUpSpeed); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                    ColumnLayout {
                        StyledText { text: "Receive"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.formatSpeed(root.networkDownSpeed); font.pixelSize: Appearance.font.pixelSize.large }
                    }
                }
            }

            DetailView {
                title: "GPU 0"
                subtitle: root.gpuName
                historyData: root.gpuHistory
                
                GridLayout {
                    Layout.fillWidth: true
                    flow: GridLayout.TopToBottom
                    rows: 3
                    columnSpacing: 40
                    rowSpacing: 10
                    
                    ColumnLayout {
                        StyledText { text: "Utilization"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.gpuUsage.toFixed(0) + "%"; font.pixelSize: Appearance.font.pixelSize.large }
                    }
                    ColumnLayout {
                        StyledText { text: "GPU Memory"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                        StyledText { text: root.gpuMemoryUsed.toFixed(0) + " / " + root.gpuMemoryTotal.toFixed(0) + " MB"; font.pixelSize: Appearance.font.pixelSize.large }
                    }
                }
            }
        }
    }
}
