pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var processes: []
    property bool updating: false
    property int cpuCores: 1

    function formatMemory(kbValue) {
        const kb = Number(kbValue)
        if (kb < 1024) {
            return kb.toFixed(0) + "KB"
        } else if (kb < 1024 * 1024) {
            const mb = kb / 1024
            if (mb >= 100) {
                return mb.toFixed(0) + "MB"
            }
            return mb.toFixed(1) + "MB"
        } else {
            const gb = kb / (1024 * 1024)
            if (gb >= 10) {
                return gb.toFixed(1) + "GB"
            }
            return gb.toFixed(2) + "GB"
        }
    }

    function killProcess(pid) {
        killProc.command = ["kill", pid.toString()]
        killProc.running = true
    }

    function forceKillProcess(pid) {
        killProc.command = ["kill", "-9", pid.toString()]
        killProc.running = true
    }

    Timer {
        interval: 2000
        running: Config.ready
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.updating) {
                psProc.running = true
            }
        }
    }

    Process {
        id: psProc
        command: [
            "ps",
            "aux",
            "--no-headers",
            "--sort=-pcpu"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.updating = true
                const lines = this.text.trim().split('\n')
                const processList = []

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i].trim()
                    if (!line) continue

                    const parts = line.split(/\s+/)
                    if (parts.length < 11) continue

                    const user = parts[0]
                    const pid = parts[1]
                    const cpuRaw = parseFloat(parts[2]) || 0
                    const cpuPercent = Math.min(100, cpuRaw / root.cpuCores)
                    const memPercent = parseFloat(parts[3])
                    const rssKb = parseInt(parts[5])
                    const command = parts.slice(10).join(' ')

                    // Extract a meaningful process name from full command
                    let processName = command
                    if (command.startsWith('[') && command.endsWith(']')) {
                        processName = command
                    } else {
                        const cmdParts = command.split(' ')
                        let baseName = cmdParts[0].split('/').pop()

                        // If it's an interpreter, try to get the actual script name (idk  any more interpreters); honestly I don't know any better way to figure out the process name, but this is better than nothing i guess
                        const interpreters = ['python', 'python2', 'python3', 'node', 'bash', 'sh', 'perl', 'ruby', 'java']
                        if (interpreters.includes(baseName) && cmdParts.length > 1) {
                            let scriptPath = cmdParts[1]
                            let argIndex = 1
                            while (argIndex < cmdParts.length && cmdParts[argIndex].startsWith('-')) {
                                argIndex++
                            }
                            if (argIndex < cmdParts.length) {
                                scriptPath = cmdParts[argIndex]
                                const scriptName = scriptPath.split('/').pop()
                                processName = baseName + ': ' + scriptName
                            } else {
                                processName = baseName
                            }
                        } else {
                            processName = baseName
                        }

                        if (processName.length > 45) {
                            processName = processName.substring(0, 42) + "..."
                        }
                    }

                    processList.push({
                        pid: pid,
                        name: processName,
                        fullCommand: command,
                        user: user,
                        cpuPercent: cpuPercent,
                        memPercent: memPercent,
                        memoryKb: rssKb,
                        memoryFormatted: root.formatMemory(rssKb)
                    })
                }

                root.processes = processList
                root.updating = false
            }
        }
    }

    Process {
    id: cpuCoreProbe
    command: ["/bin/sh", "-c",
        "nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1"
    ]
    running: true
    stdout: StdioCollector {
        onStreamFinished: {
            const n = parseInt(this.text.trim())
            if (!isNaN(n) && n > 0) root.cpuCores = n
        }
    }
}

    Process {
        id: killProc
        running: false
        onExited: {
            psProc.running = true
        }
    }

    
}
