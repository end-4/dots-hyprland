import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "systemResources"
    implicitHeight: backgroundShape.implicitHeight
    implicitWidth: backgroundShape.implicitWidth

    property bool showGraphs: Config.options.background.widgets.systemResources.showGraphs || false
    property int maxHistory: ResourceUsage.historyLength
    property var gpuUsageHistory: []
    property real currentGpuUsage: 0

    Component.onCompleted: {
        var arr = [];
        for (var i = 0; i < maxHistory; i++) arr.push(0);
        gpuUsageHistory = arr;
    }

    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: gpuProcess.running = true }

    Process {
        id: gpuProcess
        running: false
        command: ["bash", "-c",
            "if command -v nvidia-smi &>/dev/null; then nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits; " +
            "elif [ -f /sys/class/drm/card0/device/gpu_busy_percent ]; then cat /sys/class/drm/card0/device/gpu_busy_percent; " +
            "else echo 0; fi"]
        stdout: SplitParser {
            onRead: (line) => {
                var v = parseFloat(line.trim());
                if (!isNaN(v)) {
                    root.currentGpuUsage = v;
                    var arr = [...root.gpuUsageHistory, v/100.0];
                    if (arr.length > root.maxHistory) arr.shift();
                    root.gpuUsageHistory = arr;
                }
            }
        }
    }

    StyledDropShadow { target: backgroundShape }

    Rectangle {
        id: backgroundShape
        anchors.fill: parent
        radius: Appearance.rounding.windowRounding
        color: Appearance.colors.colPrimaryContainer
        implicitWidth: 350
        implicitHeight: contentCol.implicitHeight + 40

        Column {
            id: contentCol
            anchors.centerIn: parent
            spacing: 20
            width: parent.width - 40

            Row {
                spacing: 15
                MaterialSymbol { iconSize: 32; color: Appearance.colors.colOnPrimaryContainer; text: "memory"; anchors.verticalCenter: parent.verticalCenter }
                StyledText { font.pixelSize: 18; font.weight: Font.Bold; color: Appearance.colors.colOnPrimaryContainer; text: "System Resources"; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
                spacing: 30
                anchors.horizontalCenter: parent.horizontalCenter
                Column {
                    StyledText { text: "CPU"; font.pixelSize: 12; color: Appearance.colors.colPrimary }
                    StyledText { text: Math.round(ResourceUsage.cpuUsage * 100) + "%"; font.pixelSize: 18; color: Appearance.colors.colOnPrimaryContainer; font.weight: Font.Bold }
                }
                Column {
                    StyledText { text: "RAM"; font.pixelSize: 12; color: Appearance.colors.colPrimary }
                    StyledText { text: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"; font.pixelSize: 18; color: Appearance.colors.colOnPrimaryContainer; font.weight: Font.Bold }
                }
                Column {
                    StyledText { text: "GPU"; font.pixelSize: 12; color: Appearance.colors.colPrimary }
                    StyledText { text: Math.round(root.currentGpuUsage) + "%"; font.pixelSize: 18; color: Appearance.colors.colOnPrimaryContainer; font.weight: Font.Bold }
                }
            }

            Canvas {
                id: graphCanvas
                width: parent.width; height: 100; visible: root.showGraphs
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    function drawSmooth(arr, color) {
                        if (!arr || arr.length < 2) return;
                        ctx.beginPath();
                        ctx.strokeStyle = color; ctx.lineWidth = 2;
                        ctx.lineCap = "round"; ctx.lineJoin = "round";
                        var n = arr.length, step = width/(n-1);
                        ctx.moveTo(0, height - arr[0]*(height-4) - 2);
                        for (var i=1; i<n; i++) {
                            var cpx = ((i-1)*step + i*step)/2;
                            var py = height - arr[i-1]*(height-4) - 2;
                            var cy = height - arr[i]*(height-4) - 2;
                            ctx.bezierCurveTo(cpx, py, cpx, cy, i*step, cy);
                        }
                        ctx.stroke();
                    }

                    drawSmooth(root.gpuUsageHistory, Appearance.colors.colError);
                    drawSmooth(ResourceUsage.memoryUsageHistory, Appearance.colors.colSecondary);
                    drawSmooth(ResourceUsage.cpuUsageHistory, Appearance.colors.colPrimary);
                }
                Timer { interval: 1000; running: root.showGraphs; repeat: true; onTriggered: parent.requestPaint() }

                Row {
                    anchors.top: parent.bottom; anchors.topMargin: 5
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 15
                    Repeater {
                        model: [
                            { label: "CPU",  color: Appearance.colors.colPrimary },
                            { label: "RAM",  color: Appearance.colors.colSecondary },
                            { label: "GPU",  color: Appearance.colors.colError }
                        ]
                        Row {
                            spacing: 5
                            required property var modelData
                            Rectangle { width: 10; height: 10; radius: 5; color: modelData.color; anchors.verticalCenter: parent.verticalCenter }
                            StyledText { text: modelData.label; font.pixelSize: 10; color: Appearance.colors.colOnPrimaryContainer }
                        }
                    }
                }
            }

            Item { width: 1; height: root.showGraphs ? 20 : 0 }
        }
    }
}
