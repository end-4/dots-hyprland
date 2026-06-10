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
    configEntryName: "visualizer"
    implicitHeight: backgroundShape.implicitHeight
    implicitWidth: backgroundShape.implicitWidth

    property int numBars: {
        // cava requires even bar count in stereo mode — force even
        var raw = Config.options.background.widgets.visualizer.bars;
        return raw % 2 === 0 ? raw : raw + 1;
    }
    property bool isVertical: Config.options.background.widgets.visualizer.vertical
    property string style: Config.options.background.widgets.visualizer.style
    property var amplitudeArray: []
    property bool cavaReady: false

    // Cava config path — /tmp is cleared on reboot, we always regenerate it
    readonly property string cavaConfigPath: "/tmp/quickshell_cava_config"

    function buildCavaConfig() {
        return "[general]\nbars = " + root.numBars + "\nchannels = mono\n" +
               "[output]\nmethod = raw\nraw_target = /dev/stdout\n" +
               "data_format = ascii\nascii_max_range = 100\n";
    }

    // Watchdog: every 2s, if cava isn't running, write config and start it
    Timer {
        id: watchdog
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!cavaProcess.running) {
                root.cavaReady = false;
                writeConfigProcess.running = false;
                writeConfigProcess.running = true;
            }
        }
    }

    // Step 1: Write the cava config to /tmp
    Process {
        id: writeConfigProcess
        running: false
        command: ["bash", "-c",
            "printf '%s' '" + root.buildCavaConfig().replace(/'/g, "'\\''") + "' > " + root.cavaConfigPath]
        onExited: (code) => {
            if (code === 0) startDelay.start();
        }
    }

    Timer {
        id: startDelay
        interval: 100
        repeat: false
        onTriggered: {
            cavaProcess.running = true;
            root.cavaReady = true;
        }
    }

    // Step 2: Run cava, read its ascii stdout
    Process {
        id: cavaProcess
        running: false
        command: ["cava", "-p", root.cavaConfigPath]
        stdout: SplitParser {
            onRead: (line) => {
                var vals = line.split(';')
                    .map(s => parseInt(s, 10))
                    .filter(v => !isNaN(v) && v >= 0);
                if (vals.length > 0) root.amplitudeArray = vals;
            }
        }
        onRunningChanged: {
            if (!running) root.cavaReady = false;
        }
    }

    // When bar count changes, restart cava with new config
    onNumBarsChanged: {
        cavaProcess.running = false;
        writeConfigProcess.running = false;
        writeConfigProcess.running = true;
        var arr = [];
        for (let i = 0; i < numBars; i++) arr.push(0);
        amplitudeArray = arr;
    }

    Rectangle {
        id: backgroundShape
        anchors.fill: parent
        color: "transparent"
        implicitWidth:  isVertical ? 200 : (root.numBars * 10 + 40)
        implicitHeight: isVertical ? (root.numBars * 10 + 40) : 200

        Item {
            anchors.fill: parent
            anchors.margins: 20

            // Horizontal base line
            Rectangle {
                visible: !isVertical
                color: Appearance.colors.colPrimary
                height: 4; width: parent.width
                anchors.bottom: parent.bottom
                radius: 2
            }
            // Vertical base line
            Rectangle {
                visible: isVertical
                color: Appearance.colors.colPrimary
                width: 4; height: parent.height
                anchors.left: parent.left
                radius: 2
            }

            // Horizontal bars
            Row {
                anchors.fill: parent; spacing: 4
                visible: !isVertical && root.style === "bars"
                Repeater {
                    model: root.amplitudeArray
                    Rectangle {
                        required property int modelData
                        width: Math.max(1, parent.width / root.amplitudeArray.length - parent.spacing)
                        height: Math.max(2, (modelData / 100) * parent.height)
                        anchors.bottom: parent.bottom
                        color: Appearance.colors.colPrimary; radius: 2
                        Behavior on height { NumberAnimation { duration: 60; easing.type: Easing.OutSine } }
                    }
                }
            }

            // Vertical bars
            Column {
                anchors.fill: parent; spacing: 4
                visible: isVertical && root.style === "bars"
                Repeater {
                    model: root.amplitudeArray
                    Rectangle {
                        required property int modelData
                        height: Math.max(1, parent.height / root.amplitudeArray.length - parent.spacing)
                        width: Math.max(2, (modelData / 100) * parent.width)
                        anchors.left: parent.left
                        color: Appearance.colors.colPrimary; radius: 2
                        Behavior on width { NumberAnimation { duration: 60; easing.type: Easing.OutSine } }
                    }
                }
            }

            // Wave — smooth bezier curve
            Canvas {
                anchors.fill: parent
                visible: root.style === "wave"
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    var arr = root.amplitudeArray;
                    if (arr.length < 2) return;
                    ctx.beginPath();
                    ctx.strokeStyle = Appearance.colors.colPrimary;
                    ctx.lineWidth = 4; ctx.lineCap = "round"; ctx.lineJoin = "round";
                    if (!isVertical) {
                        var stepX = width / (arr.length - 1);
                        ctx.moveTo(0, height - (arr[0]/100)*height);
                        for(var i=1; i<arr.length; i++) {
                            var cpx = ((i-1)*stepX + i*stepX) / 2;
                            ctx.bezierCurveTo(cpx, height-(arr[i-1]/100)*height, cpx, height-(arr[i]/100)*height, i*stepX, height-(arr[i]/100)*height);
                        }
                    } else {
                        var stepY = height / (arr.length - 1);
                        ctx.moveTo((arr[0]/100)*width, 0);
                        for(var j=1; j<arr.length; j++) {
                            var cpy = ((j-1)*stepY + j*stepY) / 2;
                            ctx.bezierCurveTo((arr[j-1]/100)*width, cpy, (arr[j]/100)*width, cpy, (arr[j]/100)*width, j*stepY);
                        }
                    }
                    ctx.stroke();
                }
                Timer { interval: 33; running: root.style === "wave"; repeat: true; onTriggered: parent.requestPaint() }
            }
        }
    }
}
