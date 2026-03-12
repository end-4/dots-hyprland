pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Simple polled resource usage service with RAM, Swap, and CPU usage.
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
    property list<real> cpuCoreUsages: []
    property list<real> cpuCoreFreqCaps: []
    property var previousCpuStats

    property string maxAvailableMemoryString: kbToGbString(ResourceUsage.memoryTotal)
    property string maxAvailableSwapString: kbToGbString(ResourceUsage.swapTotal)
    property string maxAvailableCpuString: "--"

    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb, attachUnit = true) {
        return (kb / (1024 * 1024)).toFixed(1) + (attachUnit ? " GB" : "");
    }

    // onCpuCoreUsagesChanged: print(cpuCoreUsages)
    // onCpuCoreFreqCapsChanged: print(cpuCoreFreqCaps)

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
            const lines = textStat.split("\n")
            const currentStats = {}
            const coreUsages = []

            for (const line of lines) {
                const match = line.match(/^(cpu\d*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
                if (match) {
                    const name = match[1]
                    const stats = match.slice(2).map(Number)
                    const total = stats.reduce((a, b) => a + b, 0)
                    const idle = stats[3]

                    let usage = 0
                    if (previousCpuStats && previousCpuStats[name]) {
                        const totalDiff = total - previousCpuStats[name].total
                        const idleDiff = idle - previousCpuStats[name].idle
                        usage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
                    }

                    currentStats[name] = { total, idle }

                    if (name === "cpu") {
                        cpuUsage = usage
                    } else {
                        coreUsages.push(usage)
                    }
                }
            }
            previousCpuStats = currentStats
            cpuCoreUsages = coreUsages

            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq 2>/dev/null || lscpu | grep 'CPU max MHz' | awk '{print $4 * 1000}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                const lines = outputCollector.text.trim().split("\n")
                const caps = lines.map(line => parseFloat(line)).filter(val => !isNaN(val))
                
                if (caps.length > 0) {
                    root.cpuCoreFreqCaps = caps
                    const maxFreq = Math.max(...caps)
                    root.maxAvailableCpuString = (maxFreq / 1000000).toFixed(1) + " GHz"
                }
            }
        }
    }
}
