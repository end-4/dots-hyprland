pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, CPU, Disk, and GPU usage.
 */
Singleton {
    id: root
	property real memoryTotal: 1
	property real memoryFree: 0
	property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
	property real swapFree: 0
	property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property var previousCpuStats
    property real cpuTemp: 0  // Celsius; 0 when unavailable

    property real diskTotal: 1
    property real diskUsed: 0
    property real diskFree: 0
    property real diskUsedPercentage: 0
    property string maxAvailableDiskString: "--"

    // GPU (NVIDIA via nvidia-smi; 0 when unavailable)
    property real gpuUsage: 0
    property real gpuMemoryUsed: 0
    property real gpuMemoryTotal: 1
    property real gpuMemoryUsedPercentage: 0
    property string maxAvailableGpuString: "--"
    property bool gpuAvailable: false

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []
    property list<real> diskUsageHistory: []
    property list<real> gpuUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function updateMemoryUsageHistory() {
        memoryUsageHistory = [...memoryUsageHistory, memoryUsedPercentage]
        if (memoryUsageHistory.length > historyLength) {
            memoryUsageHistory.shift()
        }
    }
    function updateSwapUsageHistory() {
        swapUsageHistory = [...swapUsageHistory, swapUsedPercentage]
        if (swapUsageHistory.length > historyLength) {
            swapUsageHistory.shift()
        }
    }
    function updateCpuUsageHistory() {
        cpuUsageHistory = [...cpuUsageHistory, cpuUsage]
        if (cpuUsageHistory.length > historyLength) {
            cpuUsageHistory.shift()
        }
    }
    function updateDiskUsageHistory() {
        diskUsageHistory = [...diskUsageHistory, diskUsedPercentage]
        if (diskUsageHistory.length > historyLength) {
            diskUsageHistory.shift()
        }
    }
    function updateGpuUsageHistory() {
        gpuUsageHistory = [...gpuUsageHistory, gpuUsage]
        if (gpuUsageHistory.length > historyLength) {
            gpuUsageHistory.shift()
        }
    }
    function updateHistories() {
        updateMemoryUsageHistory()
        updateSwapUsageHistory()
        updateCpuUsageHistory()
    }

	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()

            // Parse memory and swap usage
            const textMeminfo = fileMeminfo.text()
            memoryTotal = Number(textMeminfo.match(/MemTotal: *(\d+)/)?.[1] ?? 1)
            memoryFree = Number(textMeminfo.match(/MemAvailable: *(\d+)/)?.[1] ?? 0)
            swapTotal = Number(textMeminfo.match(/SwapTotal: *(\d+)/)?.[1] ?? 1)
            swapFree = Number(textMeminfo.match(/SwapFree: *(\d+)/)?.[1] ?? 0)

            // Parse CPU usage
            const textStat = fileStat.text()
            const cpuLine = textStat.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
            if (cpuLine) {
                const stats = cpuLine.slice(1).map(Number)
                const total = stats.reduce((a, b) => a + b, 0)
                const idle = stats[3]

                if (previousCpuStats) {
                    const totalDiff = total - previousCpuStats.total
                    const idleDiff = idle - previousCpuStats.idle
                    cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                }

                previousCpuStats = { total, idle }
            }

            root.updateHistories()
            diskDfProcess.running = true
            cpuTempProbeProcess.running = true
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

    Process {
        id: diskDfProcess
        command: ["df", "-k", "/"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length >= 2) {
                    const parts = lines[1].trim().split(/\s+/)
                    if (parts.length >= 4) {
                        const totalK = Number(parts[1]) || 1
                        const usedK = Number(parts[2]) || 0
                        const availK = Number(parts[3]) || 0
                        root.diskTotal = totalK
                        root.diskUsed = usedK
                        root.diskFree = availK
                        root.diskUsedPercentage = totalK > 0 ? (usedK / totalK) : 0
                        root.maxAvailableDiskString = root.kbToGbString(totalK)
                        root.updateDiskUsageHistory()
                    }
                }
            }
        }
    }

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    Process {
        id: cpuTempProbeProcess
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "for hw in /sys/class/hwmon/hwmon*; do n=$(cat \"$hw/name\" 2>/dev/null); [ \"$n\" = \"k10temp\" ] || continue; for i in \"$hw\"/temp*_input; do [ -f \"$i\" ] || continue; l=\"${i%_input}_label\"; if [ -f \"$l\" ]; then lbl=$(cat \"$l\" 2>/dev/null); case \"$lbl\" in Tctl|Tdie) v=$(cat \"$i\" 2>/dev/null); [ -n \"$v\" ] && printf '%s\\n' \"$v\" && exit 0;; esac; fi; done; v=$(cat \"$hw/temp1_input\" 2>/dev/null); [ -n \"$v\" ] && printf '%s\\n' \"$v\" && exit 0; done; for z in /sys/class/thermal/thermal_zone1/temp /sys/class/thermal/thermal_zone0/temp; do [ -f \"$z\" ] || continue; v=$(cat \"$z\" 2>/dev/null); [ -n \"$v\" ] && printf '%s\\n' \"$v\" && exit 0; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = parseInt(text.trim(), 10)
                root.cpuTemp = (!isNaN(raw) && raw > 0) ? (raw / 1000) : 0
            }
        }
    }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }

    Process {
        id: gpuQueryProcess
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim().split("\n")[0]
                if (!line) return
                const parts = line.split(",").map(s => parseFloat(s.trim()))
                if (parts.length >= 3 && !parts.some(p => isNaN(p))) {
                    root.gpuUsage = Math.min(1, Math.max(0, parts[0] / 100))
                    root.gpuMemoryUsed = parts[1] * 1024  // MiB -> KB to match formatKB
                    root.gpuMemoryTotal = Math.max(1, parts[2]) * 1024
                    root.gpuMemoryUsedPercentage = root.gpuMemoryTotal > 0 ? (root.gpuMemoryUsed / root.gpuMemoryTotal) : 0
                    root.maxAvailableGpuString = (parts[2] / 1024).toFixed(1) + " GB"
                    root.gpuAvailable = true
                    root.updateGpuUsageHistory()
                }
            }
        }
    }

    Timer {
        id: gpuPollTimer
        interval: Config.options?.resources?.updateInterval ?? 3000
        running: true
        repeat: true
        onTriggered: gpuQueryProcess.running = true
    }
}
