import QtQuick
import Quickshell
import Quickshell.Io
import "../functions/ResourceMonitorUtils.js" as Utils

Item {
    id: root

    property bool active: false
    property bool processMonitorActive: false

    // CPU Info
    property int cpuCores: 1
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
    property string uptime: "---"

    // GPU Info
    property var gpuList: []
    property int selectedGpuIndex: 0
    property real gpuUsage: 0
    property real gpuMemoryUsed: 0
    property real gpuMemoryTotal: 1
    property string gpuName: "Detecting..."

    // Disk Info
    property real diskUsed: 0
    property real diskTotal: 1

    // Network Info
    property real networkDownSpeed: 0
    property real networkUpSpeed: 0
    property real previousRxBytes: 0
    property real previousTxBytes: 0

    // Process List
    property var processList: []
    
    // Signals
    signal killFinished(int exitCode)

    // --- Functions ---
    function killProcess(pid) {
        killProc.targetPid = pid
        killProc.running = true
    }
    
    function refreshProcesses() {
        if (processMonitorActive) processProc.running = true
    }

    // --- Processes ---

    Process {
        id: cpuCoresProc
        command: ["nproc"]
        running: root.active
        stdout: SplitParser {
            onRead: data => root.cpuCores = parseInt(data.trim()) || 1
        }
    }

    Process {
        id: cpuNameProc
        command: ["bash", "-c", "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //'"]
        running: root.active
        stdout: SplitParser {
            onRead: data => root.cpuName = data.trim() || "Unknown CPU"
        }
    }

    Process {
        id: cpuSpeedProc
        command: ["bash", "-c", "awk '/cpu MHz/ {print $4; exit}' /proc/cpuinfo"]
        running: root.active
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
        running: root.active
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
                        root.cpuVirtualization = "Enabled"
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
        running: root.active
        stdout: SplitParser {
            onRead: data => root.cpuThreads = parseInt(data.trim()) || 0
        }
    }

    Process {
        id: handleCountProc
        command: ["bash", "-c", "cat /proc/sys/fs/file-nr | awk '{print $1}'"]
        running: root.active
        stdout: SplitParser {
            onRead: data => root.cpuHandles = parseInt(data.trim()) || 0
        }
    }

    Process {
        id: uptimeProc
        command: ["bash", "-c", "cat /proc/uptime | awk '{print $1}'"]
        running: root.active
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

    // GPU Discovery
    property string gpuDiscoveryBuffer: ""
    Process {
        id: gpuDiscovery
        command: ["bash", "-c", "lspci -mm | grep -E 'VGA|3D|Display'"]
        running: root.active
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
                gpuProc.command = ["bash", "-c", "nvidia-smi --id=" + pciId + " --query-gpu=utilization.gpu,memory.used,memory.total,name --format=csv,noheader,nounits 2>/dev/null || printf '0,0,1,%s\\n' " + Utils.escapeShellArg(gpu.name)]
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
                          "printf \"%s,%s,%s,%s\\n\" \"$usage\" \"$mem_used\" \"$mem_total\" " + Utils.escapeShellArg(gpu.name)
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
                    root.gpuName = parts[3].trim() || "Unknown"
                }
            }
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -B1 / | tail -1 | awk '{print $3,$2}'"]
        running: root.active
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
        running: root.active
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

    Process {
        id: processProc
        command: ["bash", "-c", "LC_NUMERIC=C top -b -n 2 -d 0.5 -w 512 | awk '/PID/ {iter++} iter==2 { print $0 }'"]
        property string outputBuffer: ""
        running: root.processMonitorActive
        stdout: SplitParser {
            onRead: data => {
                processProc.outputBuffer += data + "\n"
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                const lines = processProc.outputBuffer.trim().split("\n")
                const procs = []
                for (const line of lines) {
                    if (line.includes("PID") && line.includes("USER")) continue
                    
                    const parts = line.trim().split(/\s+/)
                    if (parts.length >= 12) {
                        let rawCpu = parseFloat(parts[8]) || 0
                        // NOTE: 'top' reports CPU% as a percentage of a single core, so we normalize it if the process is using multiple cores
                        let normalizedCpu = rawCpu / root.cpuCores
                        procs.push({
                            pid: parseInt(parts[0]) || 0,
                            ppid: 0,
                            cpu: normalizedCpu,
                            mem: parseFloat(parts[9]) || 0,
                            name: parts.slice(11).join(" ") || "unknown",
                            children: [],
                            totalChildren: 0
                        })
                    }
                }
                root.processList = procs
            }
            processProc.outputBuffer = ""
        }
    }

    Process {
        id: killProc
        property int targetPid: 0
        command: ["bash", "-c", "kill -15 " + targetPid + "; sleep 1; kill -0 " + targetPid + " 2>/dev/null && kill -9 " + targetPid]
        onExited: (exitCode, exitStatus) => {
            root.killFinished(exitCode)
            if (root.processMonitorActive) processProc.running = true
        }
    }

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (gpuProc.command.length > 0) gpuProc.running = true
            diskProc.running = true
            netProc.running = true
            cpuSpeedProc.running = true
            uptimeProc.running = true
            threadCountProc.running = true
            handleCountProc.running = true
            
            if (root.processMonitorActive) processProc.running = true
        }
    }
}
