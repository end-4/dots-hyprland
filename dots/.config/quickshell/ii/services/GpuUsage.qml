pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool available: false
    property string gpuName: ""
    property int usagePercent: 0
    property int vramPercent: 0
    property real vramUsedGB: 0.0
    property real vramTotalGB: 0.0
    property int fanRpm: -1
    property int tempEdgeC: -1
    property int tempJunctionC: -1
    property int tempMemC: -1

    
    
    property bool dGpuAvailable: false
    property double dGpuUsage: 0
    property double dGpuVramUsage:0
    property double dGpuTempemperature:0
    property double dGpuVramUsedGB: 0    
    property double dGpuVramTotalGB: 0
    
    property bool iGpuAvailable: false
    property double iGpuUsage: 0
    property double iGpuVramUsage:0
    property double iGpuTempemperature:0
    property double iGpuVramUsedGB: 0    
    property double iGpuVramTotalGB: 0



    property string maxAvailableIGpuString: "100%" 
    property string maxAvailabledDGpuString: "100%"


    property list<real> iGpuUsageHistory: []
    property list<real> dGpuUsageHistory: []

    // History for graphing
    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> gpuUsageHistory: []

    property string maxAvailableGpuString: gpuName || "GPU"

    readonly property string scriptCmd: "~/.config/quickshell/ii/scripts/gpu/get_amd_gpuinfo.sh"


    function updateiGpuUsageHistory() {
        iGpuUsageHistory = [...iGpuUsageHistory, iGpuUsage]
        if (iGpuUsageHistory.length > historyLength) {
            iGpuUsageHistory.shift()
        }
    }

    function updatedGpuUsageHistory() {
        dGpuUsageHistory = [...dGpuUsageHistory, dGpuUsage]
        if (dGpuUsageHistory.length > historyLength) {
            dGpuUsageHistory.shift()
        }
    }
  function updateHistories() {
          if(iGpuAvailable) updateiGpuUsageHistory()
          if(dGpuAvailable) updatedGpuUsageHistory()
  }


  	Timer {
		interval: 1
        running: true 
        repeat: true
		onTriggered: {
            //Process process GPU info
            if(iGpuAvailable){
              iGpuinfoProc.running = true
            }

            if(dGpuAvailable){
              dGpuinfoProc.running = true
            }



            root.updateHistories()
            interval = Config.options?.resources?.updateInterval ?? 3000
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

