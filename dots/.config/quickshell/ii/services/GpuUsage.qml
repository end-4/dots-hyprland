pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string dGpuName: ""
    property bool dGpuAvailable: true
    property double dGpuUsage: 0
    property double dGpuVramUsage: 0
    property double dGpuTempemperature: 0
    property double dGpuVramUsedGB: 0
    property double dGpuVramTotalGB: 0
    property double dGpuPower: 0
    property double dGpuPowerLimit: 0
    property double dGpuFanUsage: 0

    property bool iGpuAvailable: true
    property double iGpuUsage: 0
    property double iGpuVramUsage: 0
    property double iGpuTempemperature: 0
    property double iGpuVramUsedGB: 0
    property double iGpuVramTotalGB: 0

    property string maxAvailableIGpuString: "100%"
    property string maxAvailabledDGpuString: "\n" + dGpuName

    property list<real> iGpuUsageHistory: []
    property list<real> dGpuUsageHistory: []

    // History for graphing
    readonly property int historyLength: Config?.options.resources.historyLength ?? 60
    property list<real> gpuUsageHistory: []

    property string maxAvailableGpuString: dGpuName || "GPU"

    readonly property string scriptCmd: "~/.config/quickshell/ii/scripts/gpu/get_amd_gpuinfo.sh"

    function updateiGpuUsageHistory() {
        iGpuUsageHistory = [...iGpuUsageHistory, iGpuUsage];
        if (iGpuUsageHistory.length > historyLength) {
            iGpuUsageHistory.shift();
        }
    }

    function updatedGpuUsageHistory() {
        dGpuUsageHistory = [...dGpuUsageHistory, dGpuUsage];
        if (dGpuUsageHistory.length > historyLength) {
            dGpuUsageHistory.shift();
        }
    }
    function updateHistories() {
        if (iGpuAvailable)
            updateiGpuUsageHistory();
        if (dGpuAvailable)
            updatedGpuUsageHistory();
    }

    Timer {
        interval: 1
        running: true
        repeat: true
        onTriggered: {
            if(Config.options.bar.resources.gpuLayout == -1){ //disabled gpu
                this.repeat = false
            }

            //Process process GPU info
            if (iGpuAvailable) {
                iGpuinfoProc.running = true;
            }

            if (dGpuAvailable) {
                dGpuinfoProc.running = true;
            }

            root.updateHistories();
            interval = Config.options?.resources?.updateInterval ?? 3000;
        }
    }

    Process {
        id: dGpuinfoProc
        command: ["bash", "-c", `${Directories.scriptPath}/gpu/get_dgpuinfo.sh`.replace(/file:\/\//, "")]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
              dGpuAvailable = this.text.indexOf("No GPU available") == -1;
                if (dGpuAvailable) {
                    dGpuName = this.text.match(/\sModel\s:\s(.+)/)?.[1].trim() ?? "";
                    dGpuFanUsage = this.text.match(/\sFan\s:\s(\d+)/)?.[1] ?? 0;

                    dGpuPower = this.text.match(/\sPower\s:\s(\d+)/)?.[1] ?? 0;
                    dGpuPowerLimit = this.text.match(/\sPowerLimit\s:\s(\d+)/)?.[1] ?? 0;
                    dGpuUsage = this.text.match(/\sUsage\s:\s(\d+)/)?.[1] / 100 ?? 0;
                    const vramLine = this.text.match(/\sVRAM\s:\s(\d+(?:\.\d+)?)\/(\d+(?:\.\d+)?)\s*GB/);
                    dGpuVramUsedGB = Number(vramLine?.[1] ?? 0);
                    dGpuVramTotalGB = Number(vramLine?.[2] ?? 0);

                    dGpuVramUsage = dGpuVramTotalGB > 0 ? (dGpuVramUsedGB / dGpuVramTotalGB) : 0;
                    dGpuTempemperature = this.text.match(/\sTemp\s:\s(\d+)/)?.[1] ?? 0;
                }
            }
        }
    }

    Process {
        id: iGpuinfoProc
        command: ["bash", "-c", `${Directories.scriptPath}/gpu/get_igpuinfo.sh`.replace(/file:\/\//, "")]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                iGpuAvailable = this.text.indexOf("No GPU available") == -1;
                if (iGpuAvailable) {
                    iGpuUsage = this.text.match(/\sUsage\s:\s(\d+)/)?.[1] / 100 ?? 0;
                    const vramLine = this.text.match(/\sVRAM\s:\s(\d+(?:\.\d+)?)\/(\d+(?:\.\d+)?)\s*GB/);
                    iGpuVramUsedGB = Number(vramLine?.[1] ?? 0);
                    iGpuVramTotalGB = Number(vramLine?.[2] ?? 0);
                    iGpuVramUsage = iGpuVramTotalGB > 0 ? (iGpuVramUsedGB / iGpuVramTotalGB) : 0;
                    iGpuTempemperature = this.text.match(/\sTemp\s:\s(\d+)/)?.[1] ?? 0;
                }
            }
        }
    }
}
