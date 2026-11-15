pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, CPU and GPU usage, and CPU/GPU temperature.
 * Sensors are detected once at startup: CPU temp via hwmon (AMD k10temp/zenpower, Intel coretemp),
 * GPU via amdgpu sysfs, nvidia-smi, or Intel (i915/xe) DRM fdinfo.
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
    property real cpuTemperature: 0 // °C
    property real gpuUsage: 0
    property real gpuVramUsage: 0
    property real gpuTemperature: 0 // °C
    property string gpuType: "" // "amd", "nvidia", "intel", or "" when no supported GPU
    readonly property bool gpuAvailable: gpuType !== ""
    readonly property bool gpuVramAvailable: gpuType === "amd" || gpuType === "nvidia"
    readonly property bool gpuTempAvailable: gpuType === "nvidia" || gpuTempPath !== ""
    property string cpuTempPath: ""
    property string gpuTempPath: ""
    property string amdGpuPath: "" // e.g. /sys/class/drm/card1/device
    property string intelGpuDriver: "" // "i915" or "xe"
    property var intelGpuPrevSample: ({}) // engine -> { busy, total }

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

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

            // Temperatures and GPU
            if (cpuTempPath) {
                fileCpuTemp.reload()
                cpuTemperature = Number(fileCpuTemp.text()) / 1000
            }
            if (gpuType === "amd") {
                fileGpuBusy.reload()
                fileVramUsed.reload()
                fileVramTotal.reload()
                gpuUsage = Number(fileGpuBusy.text()) / 100
                gpuVramUsage = Number(fileVramUsed.text()) / Number(fileVramTotal.text())
            } else if (gpuType === "intel") {
                intelGpuProc.running = true
            }
            if (gpuTempPath) {
                fileGpuTemp.reload()
                gpuTemperature = Number(fileGpuTemp.text()) / 1000
            }

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }
    FileView { id: fileCpuTemp; path: root.cpuTempPath }
    FileView { id: fileGpuBusy; path: root.amdGpuPath ? `${root.amdGpuPath}/gpu_busy_percent` : "" }
    FileView { id: fileVramUsed; path: root.amdGpuPath ? `${root.amdGpuPath}/mem_info_vram_used` : "" }
    FileView { id: fileVramTotal; path: root.amdGpuPath ? `${root.amdGpuPath}/mem_info_vram_total` : "" }
    FileView { id: fileGpuTemp; path: root.gpuTempPath }

    Process { // Find sensors. Prints "cpuTemp <path>", "amd <device path>", "nvidia", "intel <driver>" and "gpuTemp <path>"
        running: true
        command: ["bash", "-c", `
            for d in /sys/class/hwmon/hwmon*; do
                case "$(cat $d/name)" in k10temp|zenpower|coretemp|cpu_thermal) echo "cpuTemp $d/temp1_input"; break;; esac
            done
            # AMD: the card with the most VRAM, so a dGPU wins over an iGPU
            gpu=$(for c in /sys/class/drm/card*/device; do [ -f $c/gpu_busy_percent ] && echo "$(cat $c/mem_info_vram_total 2>/dev/null || echo 0) $c"; done | sort -n | tail -1 | cut -d' ' -f2)
            if [ -n "$gpu" ]; then
                echo "amd $gpu"
                for t in $gpu/hwmon/hwmon*/temp1_input; do [ -f $t ] && echo "gpuTemp $t"; done # edge
                for t in $gpu/hwmon/hwmon*/temp*_label; do [ "$(cat $t 2>/dev/null)" = junction ] && echo "gpuTemp \${t%_label}_input"; done
            elif nvidia-smi -L > /dev/null 2>&1; then
                echo "nvidia"
            else
                for c in /sys/class/drm/card*/device; do
                    driver=$(basename "$(readlink -f $c/driver)")
                    case "$driver" in i915|xe)
                        echo "intel $driver"
                        for t in $c/hwmon/hwmon*/temp*_input; do [ -f $t ] && echo "gpuTemp $t" && break; done # Discrete cards only
                        break;;
                    esac
                done
            fi
        `]
        stdout: SplitParser {
            onRead: line => {
                const [key, path] = line.split(" ")
                if (key === "cpuTemp") root.cpuTempPath = path
                else if (key === "amd") { root.amdGpuPath = path; root.gpuType = "amd" }
                else if (key === "gpuTemp") root.gpuTempPath = path // For AMD, junction (hotspot) overrides edge
                else if (key === "nvidia") root.gpuType = "nvidia"
                else if (key === "intel") { root.intelGpuDriver = path; root.gpuType = "intel" }
            }
        }
    }

    Process { // NVIDIA: one long-running nvidia-smi printing "usage, vramUsed, vramTotal, temp" each interval
        // ponytail: keeps a hybrid laptop's NVIDIA dGPU awake. Only used when there's no AMD GPU; check runtime PM if that matters
        running: root.gpuType === "nvidia"
        command: ["nvidia-smi", "-i", "0", "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu",
            "--format=csv,noheader,nounits", "-lms", `${Config.options?.resources?.updateInterval ?? 3000}`]
        stdout: SplitParser {
            onRead: line => {
                const [usage, vramUsed, vramTotal, temp] = line.split(",").map(Number)
                root.gpuUsage = usage / 100
                root.gpuVramUsage = vramUsed / vramTotal
                root.gpuTemperature = temp
            }
        }
    }

    Process { // Intel: sum every GPU client's engine busy time from DRM fdinfo (i915: ns, xe: cycles), like nvtop does
        // ponytail: only sees our own user's processes, and a client exiting between updates lowers that update's load
        id: intelGpuProc
        command: ["bash", "-c", `cat /proc/[0-9]*/fdinfo/* 2>/dev/null | awk -v drv=${root.intelGpuDriver} '
            /^pos:/ { d = ""; c = ""; p = "" } # Each fdinfo file starts with pos:
            /^drm-driver:/ { d = $2 }
            /^drm-client-id:/ { c = $2 }
            /^drm-pdev:/ { p = $2 }
            d == drv && /^drm-engine-[a-z-]+:/ { e = substr($1, 12); sub(":", "", e); ns[p " " c " " e] = $2 }
            d == drv && /^drm-cycles-/ { e = substr($1, 12); sub(":", "", e); cy[p " " c " " e] = $2 }
            d == drv && /^drm-total-cycles-/ { e = substr($1, 18); sub(":", "", e); if ($2 > tot[e]) tot[e] = $2 }
            END {
                for (k in ns) { split(k, a, " "); sn[a[3]] += ns[k] }
                for (e in sn) print "ns", e, sn[e]
                for (k in cy) { split(k, a, " "); sc[a[3]] += cy[k] }
                for (e in sc) print "cycles", e, sc[e], tot[e]
            }'`]
        stdout: StdioCollector {
            onStreamFinished: {
                // Load = busiest engine's share of the time (ns) or GPU cycles (xe) since the last update
                const now = Date.now() * 1e6
                const sample = {}
                let usage = 0
                for (const line of this.text.trim().split("\n")) {
                    if (!line) continue
                    const [kind, engine, busy, total] = line.split(" ")
                    sample[engine] = { busy: Number(busy), total: kind === "ns" ? now : Number(total) }
                    const prev = root.intelGpuPrevSample[engine]
                    if (prev && sample[engine].total > prev.total)
                        usage = Math.max(usage, (sample[engine].busy - prev.busy) / (sample[engine].total - prev.total))
                }
                root.intelGpuPrevSample = sample
                root.gpuUsage = Math.min(usage, 1)
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
}
