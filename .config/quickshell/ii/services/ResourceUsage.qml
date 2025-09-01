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
	property double memoryTotal: 1
	property double memoryFree: 1
	property double memoryUsed: memoryTotal - memoryFree
    property double memoryUsedPercentage: memoryUsed / memoryTotal
    property double swapTotal: 1
	property double swapFree: 1
	property double swapUsed: swapTotal - swapFree
    property double swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property double cpuUsage: 0
    property double cpuFreqency: 0
    property var previousCpuStats
    property double cpuTemperature:  0
    
    property bool dGpuAvailable: true
    property double dGpuUsage: 0
    property double dGpuVramUsage:0
    property double dGpuTempemperature:0
    property double dGpuVramUsedGB: 0    
    property double dGpuVramTotalGB: 0
    
    property bool iGpuAvailable: true
    property double iGpuUsage: 0
    property double iGpuVramUsage:0
    property double iGpuTempemperature:0
    property double iGpuVramUsedGB: 0    
    property double iGpuVramTotalGB: 0


	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            // Reload files
            fileMeminfo.reload()
            fileStat.reload()
            fileCpuinfo.reload()

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

            // Parse CPU frequency
            const cpuInfo = fileCpuinfo.text()
            const cpuCoreFrequencies = cpuInfo.match(/cpu MHz\s+:\s+(\d+\.\d+)\n/g).map(x => Number(x.match(/\d+\.\d+/)))
            const cpuCoreFreqencyAvg = cpuCoreFrequencies.reduce((a, b) => a + b, 0) / cpuCoreFrequencies.length
            cpuFreqency = cpuCoreFreqencyAvg / 1000
            

            //Process process CPU temp
            tempProc.running = true

            //Process process GPU info
            if(iGpuAvailable){
              iGpuinfoProc.running = true
            }

            if(dGpuAvailable){
              dGpuinfoProc.running = true
            }



            interval = Config.options?.resources?.updateInterval ?? 3000
        }
	}

	FileView { id: fileMeminfo; path: "/proc/meminfo" }
  FileView { id: fileStat; path: "/proc/stat" }
  FileView { id: fileCpuinfo; path: "/proc/cpuinfo" }


  Process {
    id: tempProc
    command: [
      "/bin/bash",
      "-c",
      "for d in /sys/class/hwmon/hwmon*; do if [ \"$(cat \"$d/name\" 2>/dev/null)\" = \"coretemp\" ]; then temp=$(cat \"$d\"/temp*_input 2>/dev/null | head -1); echo \"$temp\"; break; fi; done"
    ]
    running: true
    stdout: StdioCollector {
      onStreamFinished:{
        cpuTemperature = Number(this.text) /1000
       }
    }
  }

   Process {
    id: dGpuinfoProc
    command: ["bash", "-c", `${Directories.scriptPath}/gpu/get_dgpuinfo.sh`.replace(/file:\/\//, "")]
    running: true

    stdout: StdioCollector {
      onStreamFinished:{
        dGpuAvailable =  this.text.indexOf("No GPU available") ==-1
        if(dGpuAvailable){
          dGpuUsage = this.text.match(/\sUsage\s:\s(\d+)/)?.[1] /  100 ?? 0
          const vramLine = this.text.match(/\sVRAM\s:\s(\d+(?:\.\d+)?)\/(\d+(?:\.\d+)?)\s*GB/)
          dGpuVramUsedGB = Number(vramLine?.[1] ?? 0)
          dGpuVramTotalGB = Number(vramLine?.[2] ?? 0)
          dGpuVramUsage = dGpuVramTotalGB > 0 ? (dGpuVramUsedGB / dGpuVramTotalGB) : 0;
          dGpuTempemperature = this.text.match(/\sTemp\s:\s(\d+)/)?.[1] ?? 0 
        }
       }
    }
  }


  Process {
    id: iGpuinfoProc
    command: ["bash", "-c", `${Directories.scriptPath}/gpu/get_igpuinfo.sh`.replace(/file:\/\//, "")]
    running: true

    stdout: StdioCollector {
      onStreamFinished:{
        iGpuAvailable =  this.text.indexOf("No GPU available") ==-1
        if(iGpuAvailable){
          iGpuUsage = this.text.match(/\sUsage\s:\s(\d+)/)?.[1] /  100 ?? 0
          const vramLine = this.text.match(/\sVRAM\s:\s(\d+(?:\.\d+)?)\/(\d+(?:\.\d+)?)\s*GB/)
          iGpuVramUsedGB = Number(vramLine?.[1] ?? 0)
          iGpuVramTotalGB = Number(vramLine?.[2] ?? 0)
          iGpuVramUsage = iGpuVramTotalGB > 0 ? (iGpuVramUsedGB / iGpuVramTotalGB) : 0;
          iGpuTempemperature = this.text.match(/\sTemp\s:\s(\d+)/)?.[1] ?? 0 
        }
       }
    }
  }

}
