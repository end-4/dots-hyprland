import QtQuick

// Keep a bounded, in-memory history of cached UPower readings; no hardware polling.
Item {
    id: root
    property bool active: false
    property real powerWatts: NaN
    property int sampleInterval: 30000
    property int maxSamples: 30
    property var samples: []
    readonly property int sampleCount: samples.length
    readonly property real averageWatts: sampleCount > 0
        ? samples.reduce((sum, value) => sum + value, 0) / sampleCount : NaN
    readonly property bool validReading: Number.isFinite(powerWatts) && powerWatts > 0

    function reset() { samples = []; }
    function sample() {
        if (!active || !validReading) return;
        samples = samples.concat([powerWatts]).slice(-Math.max(1, maxSamples));
    }
    onActiveChanged: {
        reset();
        if (active) sample();
    }
    onPowerWattsChanged: {
        if (active && sampleCount === 0) sample();
    }
    Timer {
        objectName: "batteryPowerSampleTimer"
        interval: Math.max(1000, root.sampleInterval)
        repeat: true
        running: root.active
        onTriggered: root.sample()
    }
}
