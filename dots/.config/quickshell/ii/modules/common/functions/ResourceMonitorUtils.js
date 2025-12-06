.pragma library

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

function escapeShellArg(arg) {
    return "'" + arg.replace(/'/g, "'\\''") + "'"
}

function sortProcesses(procs, sortBy, sortAscending) {
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

function filterProcesses(procs, filterText) {
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

function filterGroups(groups, filterText) {
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

function flattenGrouped(groups, expandedGroups, filterText, sortBy, sortAscending) {
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
