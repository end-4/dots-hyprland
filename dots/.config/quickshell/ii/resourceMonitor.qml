//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.modules.ii.resourceMonitor

ApplicationWindow {
    id: root
    property int currentTab: 0

    visible: true
    onClosing: Qt.quit()
    title: "Resource Monitor"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
    }

    minimumWidth: 700
    minimumHeight: 500
    width: 800
    height: 600
    color: Appearance.m3colors.m3background

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

    property var processList: []
    property var processTree: []  // Hierarchical process list
    property var groupedProcesses: []  // Grouped by name
    property var expandedPids: ({})  // Track which processes are expanded
    property var expandedGroups: ({})  // Track which groups are expanded
    property string sortBy: "cpu"
    property bool sortAscending: false
    property string filterText: ""
    property int selectedPid: -1
    property string selectedGroup: ""

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

    function sortProcesses(procs) {
        let sorted = [...procs]
        sorted.sort((a, b) => {
            let valA, valB
            switch (sortBy) {
                case "cpu": valA = a.cpu; valB = b.cpu; break
                case "mem": valA = a.mem; valB = b.mem; break
                case "pid": valA = a.pid; valB = b.pid; break
                case "name": valA = a.name.toLowerCase(); valB = b.name.toLowerCase(); break
                default: valA = a.cpu; valB = b.cpu
            }
            if (sortAscending) return valA > valB ? 1 : -1
            return valA < valB ? 1 : -1
        })
        return sorted
    }

    function filterProcesses(procs) {
        if (!filterText) return procs
        const search = filterText.toLowerCase()
        return procs.filter(p => 
            p.name.toLowerCase().includes(search) || 
            p.pid.toString().includes(search)
        )
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

    // GPU monitoring
    Process {
        id: gpuProc
        command: ["bash", "-c", "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,name --format=csv,noheader,nounits 2>/dev/null || echo '0,0,1,No GPU'"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(", ")
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

    // Group processes by name
    function groupByName(procs) {
        var groups = {}
        for (var i = 0; i < procs.length; i++) {
            var p = procs[i]
            if (!groups[p.name]) {
                groups[p.name] = {
                    name: p.name,
                    processes: [],
                    totalCpu: 0,
                    totalMem: 0,
                    isGroup: true
                }
            }
            groups[p.name].processes.push(p)
            groups[p.name].totalCpu += p.cpu
            groups[p.name].totalMem += p.mem
        }
        
        // Convert to array and sort
        var result = []
        for (var name in groups) {
            result.push(groups[name])
        }
        
        return result
    }
    
    // Filter groups by name (keeps grouped structure)
    function filterGroups(groups) {
        if (!filterText) return groups
        var search = filterText.toLowerCase()
        var result = []
        
        for (var i = 0; i < groups.length; i++) {
            var group = groups[i]
            // Check if group name matches
            if (group.name.toLowerCase().includes(search)) {
                result.push(group)
            } else {
                // Check if any process in the group matches (by PID)
                var matchingProcs = []
                for (var j = 0; j < group.processes.length; j++) {
                    var p = group.processes[j]
                    if (p.pid.toString().includes(search)) {
                        matchingProcs.push(p)
                    }
                }
                if (matchingProcs.length > 0) {
                    // Create a filtered group with only matching processes
                    result.push({
                        name: group.name,
                        processes: matchingProcs,
                        totalCpu: matchingProcs.reduce(function(sum, p) { return sum + p.cpu }, 0),
                        totalMem: matchingProcs.reduce(function(sum, p) { return sum + p.mem }, 0),
                        isGroup: true
                    })
                }
            }
        }
        return result
    }
    
    // Flatten grouped processes for display
    function flattenGrouped(groups) {
        var result = []
        
        // Sort groups
        var sortedGroups = groups.slice()
        sortedGroups.sort(function(a, b) {
            var valA, valB
            switch (sortBy) {
                case "cpu": valA = a.totalCpu; valB = b.totalCpu; break
                case "mem": valA = a.totalMem; valB = b.totalMem; break
                case "name": valA = a.name.toLowerCase(); valB = b.name.toLowerCase(); break
                default: valA = a.totalCpu; valB = b.totalCpu
            }
            if (sortAscending) return valA > valB ? 1 : -1
            return valA < valB ? 1 : -1
        })
        
        for (var i = 0; i < sortedGroups.length; i++) {
            var group = sortedGroups[i]
            // Add group header
            result.push({
                isGroup: true,
                name: group.name,
                cpu: group.totalCpu,
                mem: group.totalMem,
                count: group.processes.length,
                pid: 0,
                depth: 0
            })
            
            // Add individual processes if expanded (or when filtering, auto-expand)
            var shouldExpand = expandedGroups[group.name] || (filterText && group.processes.length > 1)
            if (shouldExpand && group.processes.length > 1) {
                // Sort processes within group
                var sortedProcs = group.processes.slice()
                sortedProcs.sort(function(a, b) {
                    return b.cpu - a.cpu  // Sort by CPU within group
                })
                
                for (var j = 0; j < sortedProcs.length; j++) {
                    result.push({
                        isGroup: false,
                        name: sortedProcs[j].name,
                        cpu: sortedProcs[j].cpu,
                        mem: sortedProcs[j].mem,
                        pid: sortedProcs[j].pid,
                        depth: 1,
                        count: 0
                    })
                }
            }
        }
        
        return result
    }
    
    function toggleGroup(name) {
        var newExpanded = Object.assign({}, expandedGroups)
        if (newExpanded[name]) {
            delete newExpanded[name]
        } else {
            newExpanded[name] = true
        }
        expandedGroups = newExpanded
    }
    
    // Kill all processes in a group
    function killGroup(name) {
        for (var i = 0; i < processList.length; i++) {
            if (processList[i].name === name) {
                killProc.targetPid = processList[i].pid
                killProc.running = true
            }
        }
    }

    // Build tree structure from flat process list
    function buildProcessTree(procs) {
        // Create a map of pid -> process
        const procMap = {}
        for (const p of procs) {
            procMap[p.pid] = Object.assign({}, p, { children: [], childCount: 0 })
        }
        
        // Build parent-child relationships
        const roots = []
        for (const p of procs) {
            const proc = procMap[p.pid]
            if (p.ppid && procMap[p.ppid]) {
                procMap[p.ppid].children.push(proc)
                procMap[p.ppid].childCount++
            } else {
                roots.push(proc)
            }
        }
        
        // Calculate total children recursively
        function countAllChildren(proc) {
            let total = proc.children.length
            for (const child of proc.children) {
                total += countAllChildren(child)
            }
            proc.totalChildren = total
            return total
        }
        
        for (const r of roots) {
            countAllChildren(r)
        }
        
        return roots
    }
    
    // Flatten tree for display based on expanded state
    function flattenTree(tree, depth) {
        if (depth === undefined) depth = 0
        let result = []
        for (var i = 0; i < tree.length; i++) {
            var proc = tree[i]
            var item = Object.assign({}, proc, { depth: depth })
            result.push(item)
            if (proc.children.length > 0 && expandedPids[proc.pid]) {
                result = result.concat(flattenTree(proc.children, depth + 1))
            }
        }
        return result
    }
    
    function toggleExpanded(pid) {
        var newExpanded = Object.assign({}, expandedPids)
        if (newExpanded[pid]) {
            delete newExpanded[pid]
        } else {
            newExpanded[pid] = true
        }
        expandedPids = newExpanded
    }

    // Process monitoring - now includes PPID
    Process {
        id: processProc
        command: ["bash", "-c", "ps -eo pid,ppid,%cpu,%mem,comm --sort=-%cpu | head -101 | tail -100 | awk '{printf \"%s|%s|%s|%s|%s\\n\",$1,$2,$3,$4,$5}'"]
        property string outputBuffer: ""
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
                    const parts = line.split("|")
                    if (parts.length >= 5) {
                        procs.push({
                            pid: parseInt(parts[0]) || 0,
                            ppid: parseInt(parts[1]) || 0,
                            cpu: parseFloat(parts[2]) || 0,
                            mem: parseFloat(parts[3]) || 0,
                            name: parts[4] || "unknown",
                            children: [],
                            totalChildren: 0
                        })
                    }
                }
                root.processList = procs
                root.processTree = buildProcessTree(procs)
                root.groupedProcesses = groupByName(procs)
            }
            processProc.outputBuffer = ""
        }
    }

    Process {
        id: killProc
        property int targetPid: 0
        command: ["kill", "-9", targetPid.toString()]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) processProc.running = true
        }
    }

    // Update timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gpuProc.running = true
            diskProc.running = true
            netProc.running = true
            
            cpuHistory = [...cpuHistory.slice(-(historyLength - 1)), ResourceUsage.cpuUsage]
            memHistory = [...memHistory.slice(-(historyLength - 1)), ResourceUsage.memoryUsed / ResourceUsage.memoryTotal]
            gpuHistory = [...gpuHistory.slice(-(historyLength - 1)), gpuUsage / 100]
            
            // Track network speed history (normalized to max observed speed)
            var currentNetSpeed = networkDownSpeed + networkUpSpeed
            if (currentNetSpeed > maxNetSpeed) maxNetSpeed = currentNetSpeed
            var netUsage = maxNetSpeed > 0 ? currentNetSpeed / maxNetSpeed : 0
            netHistory = [...netHistory.slice(-(historyLength - 1)), Math.min(1, netUsage)]
        }
    }

    Timer {
        interval: 2000
        running: root.currentTab === 1
        repeat: true
        triggeredOnStart: true
        onTriggered: processProc.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            MaterialSymbol {
                text: "monitoring"
                iconSize: 28
                color: Appearance.m3colors.m3primary
            }

            StyledText {
                text: Translation.tr("Resource Monitor")
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer0
            }

            Item { Layout.fillWidth: true }

            // Tab buttons
            RippleButton {
                id: overviewBtn
                text: Translation.tr("Overview")
                checkable: true
                checked: root.currentTab === 0
                onClicked: root.currentTab = 0
                implicitHeight: 36
                buttonRadius: Appearance.rounding.small
                colBackground: checked ? Appearance.m3colors.m3primaryContainer : Appearance.colors.colLayer1
                contentItem: RowLayout {
                    spacing: 6
                    MaterialSymbol {
                        text: "dashboard"
                        iconSize: 18
                        color: overviewBtn.checked ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: overviewBtn.text
                        color: overviewBtn.checked ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                }
            }

            RippleButton {
                id: processesBtn
                text: Translation.tr("Processes")
                checkable: true
                checked: root.currentTab === 1
                onClicked: root.currentTab = 1
                implicitHeight: 36
                buttonRadius: Appearance.rounding.small
                colBackground: checked ? Appearance.m3colors.m3primaryContainer : Appearance.colors.colLayer1
                contentItem: RowLayout {
                    spacing: 6
                    MaterialSymbol {
                        text: "list"
                        iconSize: 18
                        color: processesBtn.checked ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: processesBtn.text
                        color: processesBtn.checked ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer1
                    }
                }
            }

            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: Appearance.rounding.full
                onClicked: root.close()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 20
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Content area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTab

            // Overview Tab
            StyledFlickable {
                contentHeight: overviewContent.implicitHeight + 20

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
                            subtitle: root.cpuCores + " cores"
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
                        }

                        ResourceCard {
                            Layout.fillWidth: true
                            title: "Swap"
                            icon: "swap_horiz"
                            value: root.formatBytes(ResourceUsage.swapUsed)
                            progress: ResourceUsage.swapTotal > 0 ? ResourceUsage.swapUsed / ResourceUsage.swapTotal : 0
                            subtitle: ResourceUsage.swapTotal > 0 ? root.formatBytes(ResourceUsage.swapTotal) + " total" : "Not configured"
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

            // Processes Tab
            ColumnLayout {
                spacing: 8

                // Search and controls
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            MaterialSymbol {
                                text: "search"
                                iconSize: 20
                                color: Appearance.colors.colSubtext
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.normal
                                clip: true
                                onTextChanged: root.filterText = text

                                Text {
                                    anchors.fill: parent
                                    text: Translation.tr("Search processes...")
                                    color: Appearance.colors.colSubtext
                                    font: parent.font
                                    visible: !parent.text && !parent.activeFocus
                                }
                            }

                            RippleButton {
                                visible: searchInput.text.length > 0
                                implicitWidth: 24
                                implicitHeight: 24
                                buttonRadius: Appearance.rounding.full
                                onClicked: searchInput.text = ""
                                contentItem: MaterialSymbol {
                                    text: "close"
                                    iconSize: 16
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }

                    RippleButton {
                        implicitWidth: 40
                        implicitHeight: 40
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colLayer1
                        onClicked: processProc.running = true
                        StyledToolTip { text: Translation.tr("Refresh") }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }

                // Header row
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 36
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Item { implicitWidth: 24 }  // Space for expand button

                        ProcessHeaderButton {
                            Layout.preferredWidth: 60
                            text: "PID"
                            sortKey: "pid"
                            currentSort: root.sortBy
                            ascending: root.sortAscending
                            onClicked: {
                                if (root.sortBy === "pid") root.sortAscending = !root.sortAscending
                                else { root.sortBy = "pid"; root.sortAscending = false }
                            }
                        }

                        ProcessHeaderButton {
                            Layout.fillWidth: true
                            text: Translation.tr("Name")
                            sortKey: "name"
                            currentSort: root.sortBy
                            ascending: root.sortAscending
                            onClicked: {
                                if (root.sortBy === "name") root.sortAscending = !root.sortAscending
                                else { root.sortBy = "name"; root.sortAscending = true }
                            }
                        }

                        ProcessHeaderButton {
                            Layout.preferredWidth: 70
                            text: "CPU %"
                            sortKey: "cpu"
                            currentSort: root.sortBy
                            ascending: root.sortAscending
                            onClicked: {
                                if (root.sortBy === "cpu") root.sortAscending = !root.sortAscending
                                else { root.sortBy = "cpu"; root.sortAscending = false }
                            }
                        }

                        ProcessHeaderButton {
                            Layout.preferredWidth: 70
                            text: "MEM %"
                            sortKey: "mem"
                            currentSort: root.sortBy
                            ascending: root.sortAscending
                            onClicked: {
                                if (root.sortBy === "mem") root.sortAscending = !root.sortAscending
                                else { root.sortBy = "mem"; root.sortAscending = false }
                            }
                        }

                        Item { implicitWidth: 36 }
                    }
                }

                // Process list with grouped view
                ListView {
                    id: processListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    
                    model: root.flattenGrouped(root.filterGroups(root.groupedProcesses))

                    delegate: Rectangle {
                        id: processItem
                        required property var modelData
                        required property int index

                        property int indent: modelData.depth || 0
                        property bool isGroupItem: modelData.isGroup || false
                        property bool hasMultiple: (modelData.count || 0) > 1
                        property bool isExpanded: root.expandedGroups[modelData.name] || false
                        property bool isSelected: isGroupItem ? (root.selectedGroup === modelData.name) : (root.selectedPid === modelData.pid)

                        width: processListView.width
                        height: 40
                        radius: Appearance.rounding.small
                        color: processItem.isSelected ? Appearance.m3colors.m3primaryContainer : 
                               (index % 2 === 0 ? "transparent" : Appearance.colors.colLayer1)

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (processItem.isGroupItem) {
                                    root.selectedGroup = (root.selectedGroup === processItem.modelData.name) ? "" : processItem.modelData.name
                                    root.selectedPid = -1
                                } else {
                                    root.selectedPid = (root.selectedPid === processItem.modelData.pid) ? -1 : processItem.modelData.pid
                                    root.selectedGroup = ""
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12 + (processItem.indent * 24)
                            anchors.rightMargin: 12
                            spacing: 4

                            // Expand/collapse button for groups
                            Item {
                                implicitWidth: 24
                                implicitHeight: 24
                                
                                RippleButton {
                                    anchors.fill: parent
                                    visible: processItem.isGroupItem && processItem.hasMultiple
                                    buttonRadius: Appearance.rounding.full
                                    onClicked: root.toggleGroup(processItem.modelData.name)
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: (processItem.isExpanded || root.filterText) ? "expand_more" : "chevron_right"
                                        iconSize: 18
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                                
                                // Dot for single process groups or child processes
                                Rectangle {
                                    visible: !processItem.isGroupItem || !processItem.hasMultiple
                                    anchors.centerIn: parent
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: Appearance.colors.colSubtext
                                    opacity: 0.5
                                }
                            }

                            StyledText {
                                Layout.preferredWidth: 60
                                text: processItem.isGroupItem ? (processItem.hasMultiple ? "(" + processItem.modelData.count + ")" : "") : processItem.modelData.pid
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.family: Appearance.font.family.monospace
                                color: processItem.isGroupItem ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: processItem.modelData.name
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: processItem.isGroupItem ? Font.Medium : Font.Normal
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.preferredWidth: 70
                                text: processItem.modelData.cpu.toFixed(1) + "%"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.family: Appearance.font.family.numbers
                                color: processItem.modelData.cpu > 50 ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1
                                horizontalAlignment: Text.AlignRight
                            }

                            StyledText {
                                Layout.preferredWidth: 70
                                text: processItem.modelData.mem.toFixed(1) + "%"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.family: Appearance.font.family.numbers
                                color: processItem.modelData.mem > 50 ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1
                                horizontalAlignment: Text.AlignRight
                            }

                            RippleButton {
                                implicitWidth: 36
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.full
                                visible: processItem.isSelected && !processItem.isGroupItem
                                colBackground: Appearance.m3colors.m3errorContainer
                                onClicked: {
                                    killProc.targetPid = processItem.modelData.pid
                                    killProc.running = true
                                }
                                StyledToolTip { text: Translation.tr("Kill process") }
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 18
                                    color: Appearance.m3colors.m3onErrorContainer
                                }
                            }
                            
                            RippleButton {
                                implicitWidth: 36
                                implicitHeight: 36
                                buttonRadius: Appearance.rounding.full
                                visible: processItem.isSelected && processItem.isGroupItem && processItem.hasMultiple
                                colBackground: Appearance.m3colors.m3errorContainer
                                onClicked: root.killGroup(processItem.modelData.name)
                                StyledToolTip { text: Translation.tr("Kill all %1 processes").arg(processItem.modelData.count) }
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete_sweep"
                                    iconSize: 18
                                    color: Appearance.m3colors.m3onErrorContainer
                                }
                            }

                            Item {
                                implicitWidth: 36
                                visible: !processItem.isSelected
                            }
                        }
                    }
                }

                // Footer
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        text: Translation.tr("%1 processes in %2 groups").arg(root.processList.length).arg(root.groupedProcesses.length)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        visible: root.filterText
                        text: Translation.tr("Showing: %1 groups").arg(root.filterGroups(root.groupedProcesses).length)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
