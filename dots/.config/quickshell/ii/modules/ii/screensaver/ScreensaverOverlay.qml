pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool active: false
    property bool lockPending: false
    property real armedAt: 0

    // Lets the lock screen hide its UI (password box, buttons) while the screensaver is showing underneath
    onActiveChanged: GlobalStates.screensaverActive = root.active
    Component.onDestruction: GlobalStates.screensaverActive = false

    readonly property string mode: Config.options?.screensaver?.mode ?? "dvd"
    readonly property string customPath: Config.options?.screensaver?.customPath ?? ""
    readonly property string imageAnimation: Config.options?.screensaver?.imageAnimation ?? "breathe"
    readonly property real speed: Math.max(0.2, Config.options?.screensaver?.speed ?? 1.0)

    readonly property string customExt: {
        const p = root.customPath.toLowerCase();
        const dot = p.lastIndexOf(".");
        return dot >= 0 ? p.substring(dot + 1) : "";
    }
    readonly property bool isVideo: ["mp4", "webm", "mkv", "mov", "avi", "m4v"].includes(customExt)
    readonly property bool isGif: ["gif", "webp", "apng"].includes(customExt)
    readonly property bool isScr: customExt === "scr"
    readonly property bool isStaticImage: root.mode === "custom" && root.customPath !== "" && !isVideo && !isGif && !isScr

    function show() {
        root.lockPending = false;
        root.armedAt = Date.now();
        root.active = true;
        if (root.mode === "custom" && root.isScr && root.customPath !== "") {
            scrProc.running = false;
            scrProc.running = true;
        }
    }

    function hide() {
        const shouldLock = root.lockPending;
        root.lockPending = false;
        root.active = false;
        if (scrProc.running) scrProc.running = false;
        if (shouldLock) {
            lockProc.running = false;
            lockProc.running = true;
        }
    }

    IpcHandler {
        target: "screensaver"
        function open(): void { root.show(); }
        function close(): void { root.hide(); }
        function toggle(): void { root.active ? root.hide() : root.show(); }
        function armLock(): void {
            if (root.active) {
                root.lockPending = true;
            } else {
                lockProc.running = false;
                lockProc.running = true;
            }
        }
    }

    Process {
        id: lockProc
        command: ["loginctl", "lock-session"]
    }

    Process {
        id: scrProc
        command: ["wine", root.customPath, "/s"]
        onExited: root.hide()
    }

    Variants {
        model: root.active ? Quickshell.screens : []
        delegate: PanelWindow {
            id: win
            required property var modelData
            readonly property var monCfg: (Config.options?.screensaver?.perMonitor ?? false)
                ? ((Config.options?.screensaver?.monitors ?? {})[modelData?.name ?? ""] ?? ({}))
                : ({})
            readonly property string effMode: monCfg.mode ?? root.mode
            readonly property string effColor: monCfg.color ?? (Config.options?.screensaver?.color ?? "#000000")
            readonly property string effCustomPath: monCfg.customPath ?? root.customPath
            readonly property string effImageAnimation: monCfg.imageAnimation ?? root.imageAnimation
            readonly property real effSpeed: Math.max(0.2, monCfg.speed ?? root.speed)
            readonly property string effExt: {
                const s = effCustomPath.toLowerCase();
                const d = s.lastIndexOf(".");
                return d >= 0 ? s.substring(d + 1) : "";
            }
            readonly property bool effIsVideo: ["mp4", "webm", "mkv", "mov", "avi", "m4v"].includes(effExt)
            readonly property bool effIsGif: ["gif", "webp", "apng"].includes(effExt)
            readonly property bool effIsScr: effExt === "scr"
            readonly property bool effIsStaticImage: effMode === "custom" && effCustomPath !== "" && !effIsVideo && !effIsGif && !effIsScr

            screen: modelData
            color: win.effMode === "color" ? win.effColor : "#000000"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:screensaver"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            FocusScope {
                id: keyScope
                anchors.fill: parent
                focus: true
                Component.onCompleted: keyScope.forceActiveFocus()
                Keys.onPressed: event => {
                    event.accepted = true;
                    root.hide();
                }

                // 1) DVD Bounce preset (or Custom static image with DVD bounce)
                Item {
                    anchors.fill: parent
                    visible: win.effMode === "dvd" || (win.effIsStaticImage && win.effImageAnimation === "dvd")

                    Item {
                        id: dvdBox
                        width: win.effIsStaticImage ? Math.min(360, win.width * 0.28) : 220
                        height: win.effIsStaticImage ? Math.min(260, win.height * 0.28) : 110
                        x: (win.width - width) * 0.35
                        y: (win.height - height) * 0.35

                        property real vx: 2.6 * win.effSpeed
                        property real vy: 2.1 * win.effSpeed
                        property int colorIdx: 0
                        readonly property var palette: ["#ff3b6b", "#00e5ff", "#ffd600", "#76ff03", "#d500f9", "#ff6d00"]

                        Timer {
                            running: parent.visible && root.active
                            interval: 16
                            repeat: true
                            onTriggered: {
                                let nx = dvdBox.x + dvdBox.vx;
                                let ny = dvdBox.y + dvdBox.vy;
                                let bounced = false;
                                if (nx <= 0) { nx = 0; dvdBox.vx = Math.abs(dvdBox.vx); bounced = true; }
                                else if (nx + dvdBox.width >= win.width) { nx = win.width - dvdBox.width; dvdBox.vx = -Math.abs(dvdBox.vx); bounced = true; }
                                if (ny <= 0) { ny = 0; dvdBox.vy = Math.abs(dvdBox.vy); bounced = true; }
                                else if (ny + dvdBox.height >= win.height) { ny = win.height - dvdBox.height; dvdBox.vy = -Math.abs(dvdBox.vy); bounced = true; }
                                dvdBox.x = nx;
                                dvdBox.y = ny;
                                if (bounced) dvdBox.colorIdx = (dvdBox.colorIdx + 1) % dvdBox.palette.length;
                            }
                        }

                        // Filled colored rectangle box with black Canvas DVD disc logo inside
                        Rectangle {
                            anchors.fill: parent
                            visible: win.effMode === "dvd"
                            radius: 14
                            color: dvdBox.palette[dvdBox.colorIdx]
                            border.width: 4
                            border.color: Qt.lighter(color, 1.35)

                            Canvas {
                                id: dvdCanvas
                                anchors.fill: parent
                                property color logoColor: dvdBox.palette[dvdBox.colorIdx]
                                onLogoColorChanged: requestPaint()
                                Component.onCompleted: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d");
                                    if (!ctx) return;
                                    ctx.clearRect(0, 0, width, height);
                                    ctx.fillStyle = "#000000";

                                    ctx.save();
                                    ctx.translate(width * 0.5, height * 0.38);
                                    ctx.transform(1, 0, -0.22, 1, 0, 0);
                                    ctx.font = "900 46px sans-serif";
                                    ctx.textAlign = "center";
                                    ctx.textBaseline = "middle";
                                    ctx.fillText("DVD", 0, 0);
                                    ctx.restore();

                                    ctx.save();
                                    ctx.translate(width * 0.5, height * 0.72);
                                    ctx.scale(1.0, 0.24);
                                    ctx.beginPath();
                                    ctx.arc(0, 0, 78, 0, Math.PI * 2);
                                    ctx.fill();
                                    ctx.globalCompositeOperation = "destination-out";
                                    ctx.beginPath();
                                    ctx.arc(0, 0, 19, 0, Math.PI * 2);
                                    ctx.fill();
                                    ctx.restore();

                                    ctx.fillStyle = logoColor;
                                    ctx.font = "900 9px sans-serif";
                                    ctx.textAlign = "center";
                                    ctx.textBaseline = "middle";
                                    ctx.fillText("V I D E O", width * 0.5, height * 0.72);
                                }
                            }
                        }
                    }
                }

                // 2) Matrix Rain / Starfield / Mystify Canvas presets
                Canvas {
                    id: fxCanvas
                    anchors.fill: parent
                    visible: win.effMode === "matrix" || win.effMode === "starfield" || win.effMode === "mystify"

                    property var drops: []
                    property var stars: []
                    property var polyPts: []
                    property var polyVel: []

                    function initFx() {
                        if (width <= 0 || height <= 0) return;
                        // Matrix
                        const cols = Math.max(10, Math.floor(width / 18));
                        const d = [];
                        for (let i = 0; i < cols; i++) d.push(Math.floor(Math.random() * (height / 18)));
                        drops = d;

                        // Starfield
                        const st = [];
                        for (let i = 0; i < 180; i++) {
                            st.push({
                                x: (Math.random() - 0.5) * width,
                                y: (Math.random() - 0.5) * height,
                                z: Math.random() * width + 1
                            });
                        }
                        stars = st;

                        // Mystify
                        const pts = [], vel = [];
                        for (let i = 0; i < 4; i++) {
                            pts.push({ x: Math.random() * width, y: Math.random() * height });
                            vel.push({ x: (Math.random() > 0.5 ? 1 : -1) * (2.5 + Math.random() * 2.5), y: (Math.random() > 0.5 ? 1 : -1) * (2.5 + Math.random() * 2.5) });
                        }
                        polyPts = pts;
                        polyVel = vel;
                    }

                    onWidthChanged: initFx()
                    onHeightChanged: initFx()
                    Component.onCompleted: initFx()

                    Timer {
                        running: fxCanvas.visible && root.active
                        interval: 33
                        repeat: true
                        onTriggered: fxCanvas.requestPaint()
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        if (!ctx || width <= 0 || height <= 0) return;

                        if (win.effMode === "matrix") {
                            ctx.fillStyle = "rgba(0, 0, 0, 0.08)";
                            ctx.fillRect(0, 0, width, height);
                            ctx.fillStyle = "#00ff41";
                            ctx.font = "16px monospace";
                            const chars = "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿ0123456789ABCDEF";
                            for (let i = 0; i < drops.length; i++) {
                                const ch = chars.charAt(Math.floor(Math.random() * chars.length));
                                ctx.fillText(ch, i * 18, drops[i] * 18);
                                if (drops[i] * 18 > height && Math.random() > 0.975) drops[i] = 0;
                                drops[i] += 0.65 * win.effSpeed;
                            }
                        } else if (win.effMode === "starfield") {
                            ctx.fillStyle = "rgba(0, 0, 0, 0.35)";
                            ctx.fillRect(0, 0, width, height);
                            const cx = width / 2, cy = height / 2;
                            for (let i = 0; i < stars.length; i++) {
                                const s = stars[i];
                                s.z -= 7 * win.effSpeed;
                                if (s.z <= 1) {
                                    s.x = (Math.random() - 0.5) * width;
                                    s.y = (Math.random() - 0.5) * height;
                                    s.z = width;
                                }
                                const sx = (s.x / s.z) * width + cx;
                                const sy = (s.y / s.z) * height + cy;
                                const r = Math.max(0.8, (1 - s.z / width) * 3.2);
                                ctx.fillStyle = "#ffffff";
                                ctx.beginPath();
                                ctx.arc(sx, sy, r, 0, Math.PI * 2);
                                ctx.fill();
                            }
                        } else if (win.effMode === "mystify") {
                            ctx.fillStyle = "rgba(0, 0, 0, 0.07)";
                            ctx.fillRect(0, 0, width, height);
                            for (let i = 0; i < polyPts.length; i++) {
                                polyPts[i].x += polyVel[i].x * win.effSpeed;
                                polyPts[i].y += polyVel[i].y * win.effSpeed;
                                if (polyPts[i].x <= 0 || polyPts[i].x >= width) polyVel[i].x *= -1;
                                if (polyPts[i].y <= 0 || polyPts[i].y >= height) polyVel[i].y *= -1;
                            }
                            ctx.strokeStyle = "#b69df8";
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.moveTo(polyPts[0].x, polyPts[0].y);
                            for (let i = 1; i < polyPts.length; i++) ctx.lineTo(polyPts[i].x, polyPts[i].y);
                            ctx.closePath();
                            ctx.stroke();
                        }
                    }
                }

                // 3) XANA Logo preset
                Image {
                    id: xanaImg
                    visible: win.effMode === "xana"
                    anchors.centerIn: parent
                    source: Qt.resolvedUrl("xana-logo.png")
                    height: win.height * 0.36
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    SequentialAnimation on opacity {
                        running: xanaImg.visible && root.active
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.45; to: 1.0; duration: Math.round(1600 / win.effSpeed); easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.0; to: 0.45; duration: Math.round(1600 / win.effSpeed); easing.type: Easing.InOutSine }
                    }
                }

                // 4) Custom Video
                Item {
                    anchors.fill: parent
                    visible: win.effMode === "custom" && win.effIsVideo && win.effCustomPath !== ""
                    MediaPlayer {
                        id: vidPlayer
                        source: (root.active && win.effMode === "custom" && win.effIsVideo && win.effCustomPath !== "")
                            ? ("file://" + win.effCustomPath) : ""
                        loops: MediaPlayer.Infinite
                        audioOutput: AudioOutput { muted: true }
                        videoOutput: vidOut
                        onSourceChanged: if (source !== "") play()
                    }
                    VideoOutput {
                        id: vidOut
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectFit
                    }
                }

                // 5) Custom GIF / Animated WebP
                AnimatedImage {
                    anchors.fill: parent
                    visible: win.effMode === "custom" && win.effIsGif && win.effCustomPath !== ""
                    source: visible ? ("file://" + win.effCustomPath) : ""
                    playing: visible && root.active
                    fillMode: Image.PreserveAspectFit
                    speed: win.effSpeed
                }

                // 6) Custom Static Image with selectable animation (breathe / knightrider / spin / dvd / float / none)
                Item {
                    id: imgStage
                    anchors.fill: parent
                    visible: win.effIsStaticImage

                    property real animPhase: 0
                    Timer {
                        running: imgStage.visible && root.active && (win.effImageAnimation === "knightrider" || win.effImageAnimation === "float")
                        interval: 16
                        repeat: true
                        onTriggered: imgStage.animPhase += 0.03 * win.effSpeed
                    }

                    Image {
                        id: customImg
                        source: win.effIsStaticImage ? ("file://" + win.effCustomPath) : ""
                        width: win.effImageAnimation === "dvd" ? dvdBox.width : Math.min(win.width * 0.65, implicitWidth > 0 ? implicitWidth : win.width * 0.5)
                        height: win.effImageAnimation === "dvd" ? dvdBox.height : Math.min(win.height * 0.65, implicitHeight > 0 ? implicitHeight : win.height * 0.5)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        x: win.effImageAnimation === "dvd" ? dvdBox.x
                           : win.effImageAnimation === "knightrider" ? ((win.width - width) / 2 + Math.sin(imgStage.animPhase) * (win.width - width) * 0.45)
                           : win.effImageAnimation === "float" ? ((win.width - width) / 2 + Math.sin(imgStage.animPhase) * 90)
                           : (win.width - width) / 2
                        y: win.effImageAnimation === "dvd" ? dvdBox.y
                           : win.effImageAnimation === "float" ? ((win.height - height) / 2 + Math.sin(imgStage.animPhase * 2) * 55)
                           : (win.height - height) / 2

                        SequentialAnimation on opacity {
                            running: imgStage.visible && root.active && win.effImageAnimation === "breathe"
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.35; to: 1.0; duration: Math.round(1500 / win.effSpeed); easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.0; to: 0.35; duration: Math.round(1500 / win.effSpeed); easing.type: Easing.InOutSine }
                        }
                        RotationAnimation on rotation {
                            running: imgStage.visible && root.active && win.effImageAnimation === "spin"
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: Math.round(4000 / win.effSpeed)
                        }
                    }

                    // Knight Rider red scanner bar along bottom edge when Knight Rider animation is chosen
                    Rectangle {
                        visible: win.effImageAnimation === "knightrider"
                        y: win.height - 8
                        width: 140
                        height: 4
                        radius: 2
                        color: "#ff1744"
                        x: (win.width - width) / 2 + Math.sin(imgStage.animPhase * 1.4) * (win.width - width) * 0.48
                    }
                }

                // Dismiss on click, key, or deliberate mouse movement (>12px after 600ms grace)
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.BlankCursor
                    property real startX: -1
                    property real startY: -1
                    onPressed: root.hide()
                    onPositionChanged: mouse => {
                        if (Date.now() - root.armedAt < 600) {
                            startX = mouse.x;
                            startY = mouse.y;
                            return;
                        }
                        if (startX < 0) {
                            startX = mouse.x;
                            startY = mouse.y;
                            return;
                        }
                        if (Math.hypot(mouse.x - startX, mouse.y - startY) > 12) {
                            root.hide();
                        }
                    }
                }
            }
        }
    }
}
