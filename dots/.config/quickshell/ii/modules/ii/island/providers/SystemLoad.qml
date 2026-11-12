pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.ii.island

// CPU and RAM from end-4's ResourceUsage service as an idle glance item, with a sparkline
// of the last 16 CPU samples. Reads service properties only; nothing is spawned here.
Item {
    id: root

    readonly property string glanceId: "load"
    readonly property int graphPoints: 16
    // CPU above this turns the item orange.
    readonly property real hotCpu: 0.85

    function publish() {
        // ResourceUsage holds placeholders (memoryTotal 1) until its first sample:
        // no "CPU 0% · RAM 0.0G" tile at startup.
        if (ResourceUsage.cpuUsageHistory.length === 0)
            return;
        const cpu = ResourceUsage.cpuUsage;
        const history = ResourceUsage.cpuUsageHistory;
        const graph = [];
        for (let i = Math.max(0, history.length - root.graphPoints); i < history.length; i++)
            graph.push(Math.max(0, Math.min(1, history[i])));

        IslandState.setGlance(root.glanceId, {
            icon: "memory",
            // memoryUsed is in kB; 1048576 kB = 1 GiB.
            text: Translation.tr("CPU %1% · RAM %2G").arg(Math.round(cpu * 100)).arg((ResourceUsage.memoryUsed / 1048576).toFixed(1)),
            priority: 40,
            graph: graph,
            color: cpu > root.hotCpu ? "#f0883e" : ""
        });
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.publish()
    }
}
