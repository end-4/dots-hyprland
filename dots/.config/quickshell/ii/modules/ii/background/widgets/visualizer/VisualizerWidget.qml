import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions as CF
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets
import qs.modules.common.models.hyprland
import Quickshell.Services.UPower

PinnedWidget {
    id: root

    configEntryName: "visualizer"

    property list<real> points: []
    property color primaryColor: Appearance.colors.colPrimary
    property bool shown: false

    property var currentPowerProfile: PowerProfiles.profile
    readonly property int autoRenderEveryXFrames: {
        switch(PowerProfiles.profile) {
            case 2: return 1  // Performance
            case 1: return 2  // Balanced
            case 0: return 4  // Power Saver
            default: return 2
        }
    }

    // Consolidated config properties from configEntry
    readonly property var config: ({
        height: configEntry?.height ?? 600,
        targetBarWidth: configEntry?.targetBarWidth ?? 50,
        barSpacing: configEntry?.barSpacing ?? 10,
        barRounding: configEntry?.barRounding ?? 0.5,
        smoothing: configEntry?.smoothing ?? 0.18,
        dataSmoothing: configEntry?.dataSmoothing ?? 0.5,
        opacity: configEntry?.opacity ?? 1.0,
        mono: configEntry?.mono ?? true,
        mode: configEntry?.mode ?? "wave",
        waveFillOpacity: configEntry?.waveFillOpacity ?? 0.5,
        waveBorderWidth: configEntry?.waveBorderWidth ?? 3,
        renderEveryXFrames: (configEntry?.renderEveryXFrames ?? -1) === -1 ? (autoRenderEveryXFrames - 1) : (configEntry.renderEveryXFrames - 1)
    })

    readonly property color waveFillColor: Qt.rgba(primaryColor.r, primaryColor.g, primaryColor.b, config.waveFillOpacity)
    property var pixelHeights: []

    height: config.height
    opacity: (shown && baseVisibility && enableAnimations.value) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    readonly property int barCount: Math.max(1, Math.floor(width / (config.targetBarWidth + config.barSpacing)))
    readonly property real exactWidth: (width - (config.barSpacing * (barCount - 1))) / barCount
    
    property real activityOpacity: 0
    Behavior on activityOpacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    
    property var renderedPoints: Array(barCount).fill(0)

    readonly property var targetPoints: {
        let raw = points;
        if (!raw || raw.length === 0) return Array(barCount).fill(0);
        let count = barCount;
        let mapped = new Array(count);
        let rawLenM1 = raw.length - 1;

        for (let i = 0; i < count; i++) {
            let progress = i / (count - 1 || 1);
            let relPos = config.mono ? (Math.abs(progress - 0.5) * 2) * rawLenM1 : progress * rawLenM1;
            let low = Math.floor(relPos), high = Math.ceil(relPos), mix = relPos - low;
            mapped[i] = (raw[low] * (1 - mix)) + (raw[high] * (high < raw.length ? mix : 0));
        }

        if (config.dataSmoothing <= 0) return mapped;
        let smoothed = new Array(count);
        let sW = config.dataSmoothing * 0.25; 
        for (let j = 0; j < count; j++) {
            let p = mapped[Math.max(0, j - 1)];
            let n = mapped[Math.min(count - 1, j + 1)];
            smoothed[j] = (p * sW) + (mapped[j] * (1.0 - 2 * sW)) + (n * sW);
        }
        return smoothed;
    }

    Row {
        id: visualizerRow
        anchors.fill: parent
        spacing: root.config.barSpacing
        opacity: 0
        visible: opacity > 0
        
        Repeater {
            model: root.barCount
            delegate: Rectangle {
                width: root.exactWidth
                height: Math.max(2, (root.targetPoints[index] / 1000) * root.height)
                anchors.bottom: parent.bottom
                radius: width * root.config.barRounding
                color: root.primaryColor
                border.width: root.config.waveBorderWidth
                border.color: root.waveFillColor

                Behavior on height { NumberAnimation { duration: root.config.smoothing * 1000; easing.type: Easing.Linear } }
            }
        }
    }

    Canvas {
        id: waveCanvas
        anchors.fill: parent
        opacity: 0
        visible: opacity > 0
        
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        property int frames: 0

        onPaint: {
            if (waveCanvas.frames >= config.renderEveryXFrames) {
                waveCanvas.frames = 0;
            }
            else {
                waveCanvas.frames += 1;
                return;
            }

            var ctx = getContext("2d");

            var ph = root.pixelHeights;
            if (!ph || ph.length < 2) return;

            ctx.reset();
            let w = width; let h = height;
            if (w <= 0 || h <= 0) return;

            let step = w / (ph.length - 1);
            ctx.beginPath();
            ctx.moveTo(0, h);
            ctx.lineTo(0, h - ph[0]);

            for (let i = 0; i < ph.length - 1; i++) {
                let x1 = i * step;
                let x2 = (i + 1) * step;
                let y1 = h - ph[i];
                let y2 = h - ph[i + 1];
                let cx = (x1 + x2) / 2;
                ctx.bezierCurveTo(cx, y1, cx, y2, x2, y2);
            }
            ctx.lineTo(w, h);
            ctx.closePath();

            ctx.fillStyle = root.waveFillColor;
            ctx.fill();

            if (root.config.waveBorderWidth > 0) {
                ctx.strokeStyle = root.primaryColor;
                ctx.lineWidth = root.config.waveBorderWidth;
                ctx.lineCap = "round"; ctx.lineJoin = "round";
                ctx.stroke();
            }
        }
    }

    states: [
        State {
            name: "bars"
            when: root.config.mode === "bars"
            PropertyChanges { target: visualizerRow; opacity: root.config.opacity * root.activityOpacity }
            PropertyChanges { target: waveCanvas; opacity: 0 }
        },
        State {
            name: "wave"
            when: root.config.mode === "wave"
            PropertyChanges { target: visualizerRow; opacity: 0 }
            PropertyChanges { target: waveCanvas; opacity: root.config.opacity * root.activityOpacity }
        }
    ]

    transitions: Transition {
        NumberAnimation { properties: "opacity"; duration: 400; easing.type: Easing.InOutQuad }
    }

    FrameAnimation {
        running: (root.activityOpacity > 0 || silenceTimer.running) && (visualizerRow.visible || waveCanvas.visible)
        onTriggered: {
            let target = root.targetPoints;
            let current = root.renderedPoints;
            let h = root.height;
            let count = target.length;
            
            if (current.length !== count) {
                root.renderedPoints = target;
                root.pixelHeights = target.map(p => (p / 1000) * h);
                if (waveCanvas.visible) waveCanvas.requestPaint();
                return;
            }

            let lerpFactor = Math.min(1.0, (frameTime * 1000) / Math.max(1, root.config.smoothing * 1000));
            let nextPoints = new Array(count);
            let nextPixels = new Array(count);

            for (let i = 0; i < count; i++) {
                let val = current[i] + (target[i] - current[i]) * lerpFactor;
                nextPoints[i] = val;
                nextPixels[i] = (val / 1000) * h;
            }
            
            root.renderedPoints = nextPoints;
            root.pixelHeights = nextPixels;

            if (waveCanvas.visible) waveCanvas.requestPaint();
        }
    }

    Timer { id: silenceTimer; interval: 1000; onTriggered: root.activityOpacity = 0 }

    onPointsChanged: {
        if (points.some(p => p > 0)) {
            root.activityOpacity = 1.0;
            silenceTimer.restart();
        }
    }
    
    HyprlandConfigOption {
        id: enableAnimations
        key: "animations:enabled"
    }
}