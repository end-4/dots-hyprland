import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root
    forceWidth: true

    property string selectedMonitor: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    readonly property bool perMonitor: Config.options?.screensaver?.perMonitor ?? false
    readonly property var monitorsMap: Config.options?.screensaver?.monitors ?? ({})

    function eff(key, fallback) {
        if (root.perMonitor && root.selectedMonitor !== "") {
            const m = root.monitorsMap[root.selectedMonitor];
            if (m && m[key] !== undefined) return m[key];
        }
        const v = Config.options?.screensaver?.[key];
        return v !== undefined ? v : fallback;
    }

    function setEff(key, val) {
        if (root.perMonitor && root.selectedMonitor !== "") {
            const all = Object.assign({}, Config.options.screensaver.monitors ?? {});
            const cur = Object.assign({}, all[root.selectedMonitor] ?? {});
            cur[key] = val;
            all[root.selectedMonitor] = cur;
            Config.options.screensaver.monitors = all;
        } else {
            Config.options.screensaver[key] = val;
        }
    }

    readonly property string effMode: eff("mode", "dvd")
    readonly property string effColor: eff("color", "#000000")
    readonly property string effCustomPath: eff("customPath", "")
    readonly property string effImageAnimation: eff("imageAnimation", "breathe")
    readonly property real effSpeed: eff("speed", 1.0)

    readonly property var customItems: Config.options?.screensaver?.customItems ?? []
    readonly property string customExt: {
        const p = effCustomPath.toLowerCase();
        const dot = p.lastIndexOf(".");
        return dot >= 0 ? p.substring(dot + 1) : "";
    }
    readonly property bool isVideo: ["mp4", "webm", "mkv", "mov", "avi", "m4v"].includes(customExt)
    readonly property bool isGif: ["gif", "webp", "apng"].includes(customExt)
    readonly property bool isScr: customExt === "scr"
    readonly property bool isVideoOrGifOrScr: isVideo || isGif || isScr
    readonly property bool isStaticImage: effMode === "custom" && effCustomPath !== "" && !isVideoOrGifOrScr
    readonly property bool showImageAnimations: isStaticImage

    readonly property var colorSwatches: [
        "#000000", "#0f172a", "#1a1b26", "#1e293b",
        "#1e3a8a", "#312e81", "#581c87", "#831843",
        "#7f1d1d", "#9a3412", "#14532d", "#134e4a",
        "#0369a1", "#d97706", "#475569", "#ffffff"
    ]

    property int renamingIndex: -1

    function addCustomItem(path) {
        const list = (Config.options.screensaver.customItems ?? []).slice();
        const existing = list.findIndex(it => it.path === path);
        if (existing === -1) {
            const parts = path.split("/");
            const base = parts[parts.length - 1] || path;
            list.push({ name: base, path: path });
            Config.options.screensaver.customItems = list;
        }
        root.setEff("customPath", path);
        root.setEff("mode", "custom");
    }

    function renameCustomItem(idx, newName) {
        const trimmed = newName.trim();
        if (!trimmed) { root.renamingIndex = -1; return; }
        const list = (Config.options.screensaver.customItems ?? []).map((it, i) =>
            i === idx ? ({ name: trimmed, path: it.path }) : it
        );
        Config.options.screensaver.customItems = list;
        root.renamingIndex = -1;
    }

    function deleteCustomItem(idx) {
        const list = (Config.options.screensaver.customItems ?? []).slice();
        const removed = list.splice(idx, 1)[0];
        Config.options.screensaver.customItems = list;
        if (removed && root.effCustomPath === removed.path) {
            if (list.length > 0) {
                root.setEff("customPath", list[0].path);
            } else {
                root.setEff("customPath", "");
                root.setEff("mode", "dvd");
            }
        }
        if (root.renamingIndex === idx) root.renamingIndex = -1;
    }

    Timer {
        id: idleSyncTimer
        interval: 200
        repeat: false
        onTriggered: {
            idleSyncProc.running = false;
            idleSyncProc.running = true;
        }
    }

    Process {
        id: idleSyncProc
        command: [
            "python3",
            Quickshell.shellPath("scripts/apply-screensaver-idle.py"),
            Config.options.screensaver.enable ? "1" : "0",
            String(Config.options.screensaver.timeoutMinutes)
        ]
    }

    Process {
        id: previewProc
        command: ["qs", "-c", "ii", "ipc", "call", "screensaver", "open"]
    }

    FileDialog {
        id: mediaPicker
        title: Translation.tr("Select screensaver media or .scr")
        nameFilters: [
            "All supported (*.png *.jpg *.jpeg *.webp *.svg *.bmp *.gif *.mp4 *.webm *.mkv *.mov *.avi *.m4v *.scr)",
            "Images (*.png *.jpg *.jpeg *.webp *.svg *.bmp)",
            "Videos & GIF (*.mp4 *.webm *.mkv *.mov *.avi *.m4v *.gif)",
            "Windows Screensaver (*.scr)",
            "All files (*)"
        ]
        onAccepted: {
            const path = selectedFile.toString().replace(/^file:\/\//, "");
            root.addCustomItem(path);
        }
    }

    ColorDialog {
        id: colorPicker
        title: Translation.tr("Select screensaver color")
        selectedColor: root.effColor
        onAccepted: root.setEff("color", selectedColor.toString())
    }

    ContentSection {
        icon: "tv"
        title: Translation.tr("Screensaver")

        ConfigSwitch {
            buttonIcon: "bedtime"
            text: Translation.tr("Enable screensaver on idle")
            checked: Config.options.screensaver.enable
            onCheckedChanged: {
                if (Config.options.screensaver.enable !== checked) {
                    Config.options.screensaver.enable = checked;
                    idleSyncTimer.restart();
                }
            }
        }

        ConfigSpinBox {
            icon: "timer"
            text: Translation.tr("Idle timeout (minutes)")
            value: Config.options.screensaver.timeoutMinutes
            from: 1
            to: 60
            stepSize: 1
            onValueChanged: {
                if (Config.options.screensaver.timeoutMinutes !== value) {
                    Config.options.screensaver.timeoutMinutes = value;
                    idleSyncTimer.restart();
                }
            }
        }

        ConfigSwitch {
            buttonIcon: "monitor"
            text: Translation.tr("Separate per monitor")
            checked: Config.options.screensaver.perMonitor ?? false
            onCheckedChanged: {
                if ((Config.options.screensaver.perMonitor ?? false) !== checked) {
                    Config.options.screensaver.perMonitor = checked;
                    if (checked && root.selectedMonitor === "" && Quickshell.screens.length > 0) {
                        root.selectedMonitor = Quickshell.screens[0].name;
                    }
                }
            }
        }

        Flow {
            visible: root.perMonitor
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: Quickshell.screens
                delegate: RippleButton {
                    id: monBtn
                    required property var modelData
                    required property int index
                    readonly property bool selected: root.selectedMonitor === modelData.name
                    implicitWidth: monRow.implicitWidth + 24
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.normal
                    colBackground: selected ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSurfaceContainerHigh
                    onClicked: root.selectedMonitor = modelData.name

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.buttonRadius
                        color: "transparent"
                        border.width: monBtn.selected ? 2 : 1
                        border.color: monBtn.selected ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    }

                    contentItem: RowLayout {
                        id: monRow
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: "desktop_windows"
                            iconSize: 18
                            color: monBtn.selected ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface
                        }
                        StyledText {
                            text: "%1 · %2 (%3×%4)".arg(monBtn.index + 1).arg(monBtn.modelData.name).arg(monBtn.modelData.width).arg(monBtn.modelData.height)
                            color: monBtn.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: monBtn.selected ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }

        ConfigSlider {
            text: Translation.tr("Speed: %1x").arg(root.effSpeed.toFixed(1))
            value: root.effSpeed
            usePercentTooltip: false
            buttonIcon: "speed"
            from: 0.3
            to: 3.0
            stopIndicatorValues: [1.0]
            onValueChanged: {
                const rounded = Math.round(value * 10) / 10;
                if (Math.abs(root.effSpeed - rounded) >= 0.05) {
                    root.setEff("speed", rounded);
                }
            }
        }

        RippleButton {
            Layout.alignment: Qt.AlignLeft
            implicitWidth: previewRow.implicitWidth + 28
            implicitHeight: 36
            buttonRadius: Appearance.rounding.full
            colBackground: Appearance.colors.colPrimary
            colBackgroundHover: Appearance.colors.colPrimaryHover
            onClicked: {
                previewProc.running = false;
                previewProc.running = true;
            }
            contentItem: RowLayout {
                id: previewRow
                anchors.centerIn: parent
                spacing: 6
                MaterialSymbol {
                    text: "play_arrow"
                    iconSize: 18
                    color: Appearance.m3colors.m3onPrimary
                }
                StyledText {
                    text: Translation.tr("Preview")
                    color: Appearance.m3colors.m3onPrimary
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                }
            }
        }

        Rectangle {
            id: miniPreview
            Layout.alignment: Qt.AlignLeft
            implicitWidth: 320
            implicitHeight: 180
            radius: Appearance.rounding.normal
            clip: true
            color: root.effMode === "color" ? root.effColor : "#000000"
            border.width: 2
            border.color: Appearance.colors.colOutlineVariant

            readonly property bool previewLoading: miniPreviewLoader.status !== Loader.Ready
                || (miniPreviewLoader.item?.isMediaLoading ?? false)

            Timer {
                id: miniPreviewBootTimer
                interval: 150
                running: root.visible && !miniPreviewLoader.active
                onTriggered: miniPreviewLoader.active = true
            }

            Loader {
                id: miniPreviewLoader
                anchors.fill: parent
                active: false
                asynchronous: true
                sourceComponent: miniPreviewContentComp
            }

            // Spinning loading circle shown until menu & preview finish loading
            Item {
                anchors.fill: parent
                visible: miniPreview.previewLoading
                z: 10

                CircularProgress {
                    id: miniSpinner
                    anchors.centerIn: parent
                    implicitSize: 34
                    lineWidth: 3
                    value: 0.72
                    enableAnimation: false
                    colPrimary: Appearance.colors.colPrimary
                    colSecondary: Qt.rgba(1, 1, 1, 0.16)

                    RotationAnimator on rotation {
                        running: miniPreview.previewLoading && root.visible
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                }
            }

            Component {
                id: miniPreviewContentComp
                Item {
                    id: previewStage
                    anchors.fill: parent
                    readonly property bool isMediaLoading: (vidLoader.active && vidLoader.status !== Loader.Ready)
                        || (vidLoader.item?.loading ?? false)
                        || (miniGifImg.visible && miniGifImg.status === Image.Loading)
                        || (miniCustomImg.visible && miniCustomImg.status === Image.Loading)

                    // Mini DVD bounce
                    Item {
                        anchors.fill: parent
                        visible: root.effMode === "dvd" || (root.isStaticImage && root.effImageAnimation === "dvd")

                        Item {
                            id: miniDvdBox
                            width: root.isStaticImage ? 76 : 64
                            height: root.isStaticImage ? 54 : 34
                            x: 40
                            y: 30
                            property real vx: 1.4 * root.effSpeed
                            property real vy: 1.1 * root.effSpeed
                            property int colorIdx: 0
                            readonly property var palette: ["#ff3b6b", "#00e5ff", "#ffd600", "#76ff03", "#d500f9", "#ff6d00"]

                            Timer {
                                running: parent.visible && root.visible
                                interval: 20
                                repeat: true
                                onTriggered: {
                                    let nx = miniDvdBox.x + miniDvdBox.vx;
                                    let ny = miniDvdBox.y + miniDvdBox.vy;
                                    let bounced = false;
                                    if (nx <= 0) { nx = 0; miniDvdBox.vx = Math.abs(miniDvdBox.vx); bounced = true; }
                                    else if (nx + miniDvdBox.width >= miniPreview.width) { nx = miniPreview.width - miniDvdBox.width; miniDvdBox.vx = -Math.abs(miniDvdBox.vx); bounced = true; }
                                    if (ny <= 0) { ny = 0; miniDvdBox.vy = Math.abs(miniDvdBox.vy); bounced = true; }
                                    else if (ny + miniDvdBox.height >= miniPreview.height) { ny = miniPreview.height - miniDvdBox.height; miniDvdBox.vy = -Math.abs(miniDvdBox.vy); bounced = true; }
                                    miniDvdBox.x = nx;
                                    miniDvdBox.y = ny;
                                    if (bounced) miniDvdBox.colorIdx = (miniDvdBox.colorIdx + 1) % miniDvdBox.palette.length;
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: root.effMode === "dvd"
                                radius: 6
                                color: miniDvdBox.palette[miniDvdBox.colorIdx]
                                border.width: 2
                                border.color: Qt.lighter(color, 1.35)
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "DVD"
                                        color: "#000000"
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.italic: true
                                    }
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 34
                                        height: 6
                                        radius: 3
                                        color: "#000000"
                                    }
                                }
                            }
                        }
                    }

                    // Mini Matrix / Starfield / Mystify
                    Canvas {
                        id: miniFxCanvas
                        anchors.fill: parent
                        visible: root.effMode === "matrix" || root.effMode === "starfield" || root.effMode === "mystify"
                        property var drops: []
                        property var stars: []
                        property var polyPts: []
                        property var polyVel: []

                        onVisibleChanged: if (visible) initFx()
                        onWidthChanged: if (visible) initFx()
                        Component.onCompleted: if (visible) initFx()

                        function initFx() {
                            const cols = Math.max(8, Math.floor(width / 10));
                            drops = [];
                            for (let i = 0; i < cols; i++) drops.push(Math.random() * height / 10);
                            stars = [];
                            for (let i = 0; i < 45; i++) {
                                stars.push({ x: (Math.random() - 0.5) * width, y: (Math.random() - 0.5) * height, z: Math.random() * width + 1 });
                            }
                            polyPts = [];
                            polyVel = [];
                            for (let i = 0; i < 4; i++) {
                                polyPts.push({ x: Math.random() * width, y: Math.random() * height });
                                polyVel.push({ x: (Math.random() * 2 + 1) * (Math.random() < 0.5 ? -1 : 1), y: (Math.random() * 2 + 1) * (Math.random() < 0.5 ? -1 : 1) });
                            }
                        }

                        Timer {
                            running: miniFxCanvas.visible && root.visible
                            interval: 33
                            repeat: true
                            onTriggered: miniFxCanvas.requestPaint()
                        }

                        onPaint: {
                            const ctx = getContext("2d");
                            if (width <= 0 || height <= 0) return;
                            if (root.effMode === "matrix") {
                                ctx.fillStyle = "rgba(0, 0, 0, 0.16)";
                                ctx.fillRect(0, 0, width, height);
                                ctx.fillStyle = "#00ff66";
                                ctx.font = "bold 9px monospace";
                                const chars = "01アイウエオカキクケコ";
                                for (let i = 0; i < drops.length; i++) {
                                    const ch = chars[Math.floor(Math.random() * chars.length)];
                                    ctx.fillText(ch, i * 10, drops[i] * 10);
                                    if (drops[i] * 10 > height && Math.random() > 0.94) drops[i] = 0;
                                    drops[i] += 0.65 * root.effSpeed;
                                }
                            } else if (root.effMode === "starfield") {
                                ctx.fillStyle = "rgba(0, 0, 0, 0.3)";
                                ctx.fillRect(0, 0, width, height);
                                const cx = width / 2, cy = height / 2;
                                for (let i = 0; i < stars.length; i++) {
                                    const s = stars[i];
                                    s.z -= 4 * root.effSpeed;
                                    if (s.z <= 1) { s.x = (Math.random() - 0.5) * width; s.y = (Math.random() - 0.5) * height; s.z = width; }
                                    const sx = cx + (s.x / s.z) * width;
                                    const sy = cy + (s.y / s.z) * height;
                                    const r = Math.max(0.7, (1 - s.z / width) * 2.2);
                                    ctx.fillStyle = "#ffffff";
                                    ctx.beginPath();
                                    ctx.arc(sx, sy, r, 0, Math.PI * 2);
                                    ctx.fill();
                                }
                            } else if (root.effMode === "mystify") {
                                ctx.fillStyle = "rgba(0, 0, 0, 0.12)";
                                ctx.fillRect(0, 0, width, height);
                                if (polyPts.length < 4) return;
                                for (let i = 0; i < 4; i++) {
                                    polyPts[i].x += polyVel[i].x * root.effSpeed;
                                    polyPts[i].y += polyVel[i].y * root.effSpeed;
                                    if (polyPts[i].x <= 0 || polyPts[i].x >= width) polyVel[i].x *= -1;
                                    if (polyPts[i].y <= 0 || polyPts[i].y >= height) polyVel[i].y *= -1;
                                }
                                ctx.strokeStyle = "#b69df8";
                                ctx.lineWidth = 1.5;
                                ctx.beginPath();
                                ctx.moveTo(polyPts[0].x, polyPts[0].y);
                                for (let i = 1; i < 4; i++) ctx.lineTo(polyPts[i].x, polyPts[i].y);
                                ctx.closePath();
                                ctx.stroke();
                            }
                        }
                    }

                    // Mini XANA
                    Image {
                        id: miniXanaImg
                        visible: root.effMode === "xana"
                        anchors.centerIn: parent
                        source: visible ? ("file://" + Quickshell.shellPath("modules/ii/screensaver/xana-logo.png")) : ""
                        height: miniPreview.height * 0.45
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        asynchronous: true
                        SequentialAnimation on opacity {
                            running: miniXanaImg.visible && root.visible
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.45; to: 1.0; duration: Math.round(1600 / root.effSpeed); easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.0; to: 0.45; duration: Math.round(1600 / root.effSpeed); easing.type: Easing.InOutSine }
                        }
                    }

                    // Mini Custom Video (lazy-loaded only when needed)
                    Loader {
                        id: vidLoader
                        anchors.fill: parent
                        asynchronous: true
                        active: root.effMode === "custom" && root.isVideo && root.effCustomPath !== ""
                        sourceComponent: Item {
                            anchors.fill: parent
                            readonly property bool loading: miniVidPlayer.mediaStatus === MediaPlayer.LoadingMedia
                                || miniVidPlayer.mediaStatus === MediaPlayer.BufferingMedia
                            MediaPlayer {
                                id: miniVidPlayer
                                source: (root.visible && root.effMode === "custom" && root.isVideo && root.effCustomPath !== "")
                                    ? ("file://" + root.effCustomPath) : ""
                                loops: MediaPlayer.Infinite
                                playbackRate: root.effSpeed
                                audioOutput: AudioOutput { muted: true }
                                videoOutput: miniVidOut
                                onSourceChanged: if (source.toString() !== "") play()
                            }
                            VideoOutput {
                                id: miniVidOut
                                anchors.fill: parent
                                fillMode: VideoOutput.PreserveAspectFit
                            }
                        }
                    }

                    // Mini Custom GIF
                    AnimatedImage {
                        id: miniGifImg
                        anchors.fill: parent
                        visible: root.effMode === "custom" && root.isGif && root.effCustomPath !== ""
                        source: visible ? ("file://" + root.effCustomPath) : ""
                        fillMode: Image.PreserveAspectFit
                        playing: visible && root.visible
                        speed: root.effSpeed
                        asynchronous: true
                    }

                    // Mini Custom Static Image
                    Item {
                        id: miniImgStage
                        anchors.fill: parent
                        visible: root.isStaticImage
                        property real animPhase: 0
                        Timer {
                            running: miniImgStage.visible && root.visible && (root.effImageAnimation === "knightrider" || root.effImageAnimation === "float")
                            interval: 20
                            repeat: true
                            onTriggered: miniImgStage.animPhase += 0.04 * root.effSpeed
                        }
                        Image {
                            id: miniCustomImg
                            source: root.isStaticImage ? ("file://" + root.effCustomPath) : ""
                            asynchronous: true
                            width: root.effImageAnimation === "dvd" ? miniDvdBox.width : miniPreview.width * 0.65
                            height: root.effImageAnimation === "dvd" ? miniDvdBox.height : miniPreview.height * 0.65
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            x: root.effImageAnimation === "dvd" ? miniDvdBox.x
                               : root.effImageAnimation === "knightrider" ? ((miniPreview.width - width) / 2 + Math.sin(miniImgStage.animPhase) * (miniPreview.width - width) * 0.45)
                               : root.effImageAnimation === "float" ? ((miniPreview.width - width) / 2 + Math.sin(miniImgStage.animPhase) * 20)
                               : (miniPreview.width - width) / 2
                            y: root.effImageAnimation === "dvd" ? miniDvdBox.y
                               : root.effImageAnimation === "float" ? ((miniPreview.height - height) / 2 + Math.sin(miniImgStage.animPhase * 2) * 12)
                               : (miniPreview.height - height) / 2
                            SequentialAnimation on opacity {
                                running: miniImgStage.visible && root.visible && root.effImageAnimation === "breathe"
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.35; to: 1.0; duration: Math.round(1500 / root.effSpeed); easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.0; to: 0.35; duration: Math.round(1500 / root.effSpeed); easing.type: Easing.InOutSine }
                            }
                            RotationAnimator on rotation {
                                running: miniImgStage.visible && root.visible && root.effImageAnimation === "spin"
                                from: 0; to: 360
                                duration: Math.round(4000 / root.effSpeed)
                                loops: Animation.Infinite
                            }
                        }
                    }

                    // Mini .scr badge
                    StyledText {
                        anchors.centerIn: parent
                        visible: root.effMode === "custom" && root.isScr
                        text: "Wine .scr"
                        color: "#ffffff"
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }

            // Monitor badge when per-monitor is active
            Rectangle {
                visible: root.perMonitor && root.selectedMonitor !== ""
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                radius: Appearance.rounding.full
                color: Qt.rgba(0, 0, 0, 0.6)
                implicitWidth: monBadgeTxt.implicitWidth + 14
                implicitHeight: 20
                StyledText {
                    id: monBadgeTxt
                    anchors.centerIn: parent
                    text: root.selectedMonitor
                    color: "#ffffff"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                }
            }
        }
    }

    ContentSection {
        icon: "style"
        title: Translation.tr("Style")

        ConfigSelectionArray {
            currentValue: root.effMode
            onSelected: newValue => {
                root.setEff("mode", newValue);
                if (newValue === "custom" && root.effCustomPath === "" && root.customItems.length > 0) {
                    root.setEff("customPath", root.customItems[0].path);
                }
            }
            options: [
                { displayName: "DVD", icon: "album", value: "dvd" },
                { displayName: "Matrix", icon: "terminal", value: "matrix" },
                { displayName: "Starfield", icon: "auto_awesome", value: "starfield" },
                { displayName: "Mystify", icon: "polyline", value: "mystify" },
                { displayName: "XANA", icon: "adjust", value: "xana" },
                { displayName: Translation.tr("Color"), icon: "palette", value: "color" },
                { displayName: Translation.tr("Custom"), icon: "folder_open", value: "custom" }
            ]
        }

        ContentSubsection {
            visible: root.customItems.length > 0
            title: Translation.tr("Custom")

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: root.customItems
                    delegate: Item {
                        id: chipWrap
                        required property var modelData
                        required property int index
                        readonly property bool active: root.effMode === "custom" && root.effCustomPath === modelData.path
                        readonly property bool isRenaming: root.renamingIndex === index
                        implicitWidth: isRenaming ? 200 : chipBtn.implicitWidth
                        implicitHeight: 34

                        RippleButton {
                            id: chipBtn
                            visible: !chipWrap.isRenaming
                            anchors.fill: parent
                            implicitWidth: chipRow.implicitWidth + 20
                            implicitHeight: 34
                            buttonRadius: Appearance.rounding.full
                            colBackground: chipWrap.active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSurfaceContainerHigh
                            onClicked: {
                                root.setEff("customPath", chipWrap.modelData.path);
                                root.setEff("mode", "custom");
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: chipMenu.popup()
                            }
                            contentItem: RowLayout {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 6
                                MaterialSymbol {
                                    text: "perm_media"
                                    iconSize: 16
                                    color: chipWrap.active ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurface
                                }
                                StyledText {
                                    text: chipWrap.modelData.name
                                    color: chipWrap.active ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface
                                    font.pixelSize: Appearance.font.pixelSize.small
                                }
                            }

                            Menu {
                                id: chipMenu
                                MenuItem {
                                    text: Translation.tr("Rename")
                                    onTriggered: root.renamingIndex = chipWrap.index
                                }
                                MenuItem {
                                    text: Translation.tr("Delete")
                                    onTriggered: root.deleteCustomItem(chipWrap.index)
                                }
                            }
                        }

                        TextField {
                            visible: chipWrap.isRenaming
                            anchors.fill: parent
                            text: chipWrap.modelData.name
                            onVisibleChanged: if (visible) { forceActiveFocus(); selectAll(); }
                            onAccepted: root.renameCustomItem(chipWrap.index, text)
                            Keys.onEscapePressed: root.renamingIndex = -1
                        }
                    }
                }
            }
        }
    }

    ContentSection {
        visible: root.effMode === "color"
        icon: "palette"
        title: Translation.tr("Color")

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: root.colorSwatches
                delegate: RippleButton {
                    id: swatchBtn
                    required property string modelData
                    readonly property bool selected: root.effColor.toLowerCase() === modelData.toLowerCase()
                    implicitWidth: 36
                    implicitHeight: 36
                    buttonRadius: Appearance.rounding.full
                    colBackground: modelData
                    onClicked: root.setEff("color", modelData)

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.buttonRadius
                        color: "transparent"
                        border.width: swatchBtn.selected ? 3 : 1
                        border.color: swatchBtn.selected ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: Appearance.rounding.full
                color: root.effColor
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant
            }

            StyledText {
                Layout.fillWidth: true
                text: root.effColor.toUpperCase()
                color: Appearance.m3colors.m3onSurface
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: Appearance.font.family.monospace
            }

            RippleButton {
                implicitWidth: pickColorTxt.implicitWidth + 24
                implicitHeight: 34
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colSecondaryContainer
                onClicked: colorPicker.open()
                contentItem: StyledText {
                    id: pickColorTxt
                    anchors.centerIn: parent
                    text: Translation.tr("Pick Color")
                    color: Appearance.colors.colOnSecondaryContainer
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                }
            }
        }
    }

    ContentSection {
        visible: root.effMode === "custom"
        icon: "perm_media"
        title: Translation.tr("Add / Select Custom Media")

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: root.effCustomPath !== "" ? root.effCustomPath : Translation.tr("No file selected (image, GIF, video, or .scr)")
                color: root.effCustomPath !== "" ? Appearance.m3colors.m3onSurface : Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                elide: Text.ElideMiddle
            }

            RippleButton {
                implicitWidth: browseTxt.implicitWidth + 24
                implicitHeight: 34
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colSecondaryContainer
                onClicked: mediaPicker.open()
                contentItem: StyledText {
                    id: browseTxt
                    anchors.centerIn: parent
                    text: Translation.tr("Choose File")
                    color: Appearance.colors.colOnSecondaryContainer
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                }
            }
        }

        ContentSubsection {
            visible: root.showImageAnimations
            title: Translation.tr("Image Animation")

            ConfigSelectionArray {
                currentValue: root.effImageAnimation
                onSelected: newValue => {
                    root.setEff("imageAnimation", newValue);
                }
                options: [
                    { displayName: "Breathe", icon: "air", value: "breathe" },
                    { displayName: "Knight Rider", icon: "linear_scale", value: "knightrider" },
                    { displayName: "Spin", icon: "rotate_right", value: "spin" },
                    { displayName: "DVD", icon: "open_with", value: "dvd" },
                    { displayName: "Float", icon: "waves", value: "float" },
                    { displayName: "None", icon: "block", value: "none" }
                ]
            }
        }
    }
}
