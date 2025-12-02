import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.resourceMonitor

ColumnLayout {
    id: root
    spacing: 8

    property var processList: []
    property var groupedProcesses: []
    property var expandedGroups: ({})
    property string sortBy: "cpu"
    property bool sortAscending: false
    property string filterText: ""
    property int selectedPid: -1
    property string selectedGroup: ""
    property int cpuCores: 1

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
        
        var result = []
        for (var name in groups) {
            result.push(groups[name])
        }
        
        return result
    }
    
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
    
    function flattenGrouped(groups) {
        var result = []
        
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
    
    function killGroup(name) {
        for (var i = 0; i < processList.length; i++) {
            if (processList[i].name === name) {
                killProc.targetPid = processList[i].pid
                killProc.running = true
            }
        }
    }

    Process {
        id: cpuCount
        command: ["nproc"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var cores = parseInt(data.trim())
                if (cores > 0) root.cpuCores = cores
            }
        }
    }

    Process {
        id: processProc
        command: ["bash", "-c", "LC_NUMERIC=C top -b -n 2 -d 0.5 -w 512 | awk '/PID/ {iter++} iter==2 { print $0 }'"]
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
                    // Skip header line
                    if (line.includes("PID") && line.includes("USER")) continue
                    
                    const parts = line.trim().split(/\s+/)
                    if (parts.length >= 12) {
                        let rawCpu = parseFloat(parts[8]) || 0
                        let normalizedCpu = rawCpu / root.cpuCores
                        procs.push({
                            pid: parseInt(parts[0]) || 0,
                            ppid: 0, // top doesn't show ppid by default in this view
                            cpu: normalizedCpu,
                            mem: parseFloat(parts[9]) || 0,
                            name: parts.slice(11).join(" ") || "unknown",
                            children: [],
                            totalChildren: 0
                        })
                    }
                }
                root.processList = procs
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

    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: processProc.running = true
    }

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
                horizontalAlignment: Text.AlignHCenter
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
                horizontalAlignment: Text.AlignHCenter
                onClicked: {
                    if (root.sortBy === "mem") root.sortAscending = !root.sortAscending
                    else { root.sortBy = "mem"; root.sortAscending = false }
                }
            }

            Item { implicitWidth: 36 }
        }
    }

    // Process list with grouped view
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: processListView
            anchors.fill: parent
            clip: true
            spacing: 2
            cacheBuffer: 2000

            // Keep track of the first visible index (delegate height is fixed at 40)
            property int savedFirstIndex: 0
            property bool restoringPosition: false

            onContentYChanged: {
                if (!restoringPosition) savedFirstIndex = Math.max(0, Math.floor(contentY / 40))
            }

            onModelChanged: {
                // Restore position after the model updates. Use callLater to wait for layout.
                restoringPosition = true
                Qt.callLater(function() {
                    var idx = Math.min(savedFirstIndex, Math.max(0, count - 1))
                    if (idx >= 0) positionViewAtIndex(idx, ListView.Beginning)
                    restoringPosition = false
                })
            }
            
            model: root.flattenGrouped(root.filterGroups(root.groupedProcesses))

            delegate: ProcessListItem {
                width: processListView.width
                isExpanded: root.expandedGroups[modelData.name] || false
                isSelected: isGroupItem ? (root.selectedGroup === modelData.name) : (root.selectedPid === modelData.pid)
                filterActive: root.filterText.length > 0
                
                onItemClicked: {
                    if (isGroupItem) {
                        root.selectedGroup = (root.selectedGroup === modelData.name) ? "" : modelData.name
                        root.selectedPid = -1
                    } else {
                        root.selectedPid = (root.selectedPid === modelData.pid) ? -1 : modelData.pid
                        root.selectedGroup = ""
                    }
                }
                
                onToggleGroup: name => root.toggleGroup(name)
                onKillGroup: name => root.killGroup(name)
                onKillProcess: pid => {
                    killProc.targetPid = pid
                    killProc.running = true
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            visible: root.processList.length === 0
            spacing: 10

            IconImage {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 64
                implicitHeight: 64
                source: Quickshell.iconPath("illogical-impulse")
                
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: parent.visible
                    NumberAnimation { from: 1; to: 0.3; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.3; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
                }
            }

            StyledText {
                text: Translation.tr("Loading processes...")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.normal
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
