import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.island
import "opencodeLight.js" as OpencodeLight

// What the island shows while sitting in the bar. Priority:
// flash > urgent activity (>= 50) > music > Claude > other activity > idle.
// While music plays, Claude shows as the logo in place of the equaliser.
// Right slot: Claude logo (zooming / waiting) or the real-audio equaliser.
Item {
    id: root
    property bool animate: true // live motion only on the focused screen (repaints cost CPU)
    property bool interactive: true // false while the island is open (the player handles input)
    property bool celebrating: false // keep the logo up while it throws confetti
    property bool opencodeCelebrating: false
    // DJ pill shows only music; the main pill shows everything else (music lives in DJ).
    property bool djPill: false
    property bool allowMusic: true
    // One agent logo at a time: Claude, unless only opencode is waiting for you.
    readonly property bool claude: !djPill && (IslandState.live !== null || celebrating) && !(opencodeWaiting && !waiting)
    readonly property bool waiting: IslandState.waiting
    readonly property bool opencodeWaiting: IslandState.opencodeWaiting
    readonly property bool hasMusic: allowMusic && (IslandState.playing || IslandState.musicRecent) && MprisController.activePlayer !== null && (MprisController.activeTrack?.title ?? "").length > 0
    readonly property bool opencode: !djPill && !claude && (IslandState.opencodeLive !== null || opencodeCelebrating)
    // OpenCode: "working" | "permission" | "question" | "retry" | "compact"
    readonly property string opencodeState: IslandState.opencodeState
    readonly property bool opencodeRetrying: opencode && IslandState.opencodeLive !== null && !opencodeWaiting && opencodeState === "retry"
    // Working and compacting both show the sweeping light.
    readonly property bool opencodeWorking: opencode && IslandState.opencodeLive !== null && !opencodeWaiting && !opencodeRetrying
    readonly property bool claudeWorking: claude && IslandState.live !== null && !waiting
    readonly property var act: djPill ? null : IslandState.topActivity
    readonly property string mode: djPill ? "music"
        : IslandState.flashItem ? "flash"
        : (act && act.priority >= 50) ? "activity"
        : hasMusic ? "music" // with Claude/Opencode working, the logo takes the equaliser's spot
        : claude ? "claude"
        : opencode ? "opencode"
        : act ? "activity"
        : "idle"
    readonly property bool showsSlot: mode === "claude" || mode === "opencode" || mode === "music"
    readonly property color accent: IslandState.accent.a > 0 ? IslandState.accent : Appearance.colors.colPrimary
    // Centre of the logo / equaliser slot in this item's coordinates (confetti origin).
    readonly property point slotCenter: Qt.point(row.x + slot.x + slot.width / 2, row.y + slot.y + slot.height / 2)
    signal logoHovered(bool hovered)

    // Idle glance: rotate through provider items (weather, updates, batteries...) and the unread count.
    readonly property var glanceItems: {
        const items = Object.values(IslandState.glances);
        if (IslandState.unread > 0)
            items.push({ id: "unread", icon: "notifications_unread", text: Translation.tr("%1 unread").arg(IslandState.unread), command: [], color: "", priority: 75, graph: [] });
        // Problems and warnings first, calm info last.
        return items.sort((a, b) => (b.priority ?? 50) - (a.priority ?? 50));
    }
    property bool paused: false // hovering the pill pauses the rotation
    property int glanceIndex: 0
    readonly property var glance: glanceItems.length > 0 ? glanceItems[glanceIndex % glanceItems.length] : null
    Timer {
        interval: 6000
        repeat: true
        running: root.mode === "idle" && root.glanceItems.length > 1 && !root.paused
        onTriggered: root.glanceIndex = (root.glanceIndex + 1) % root.glanceItems.length
    }

    // Smooth mode changes: the new content eases up into place.
    property real enterOffset: 0
    property real enterOpacity: 1
    onModeChanged: enterAnim.restart()
    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: root; property: "enterOffset"; from: 9; to: 0; duration: 380; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "enterOpacity"; from: 0; to: 1; duration: 300 }
    }
    property real now: Date.now()

    // Record physics: speed eases toward the target (36°/s = one turn per 10 s),
    // so play spins up and pause coasts down; the angle is kept while stopped.
    property real discAngle: 0
    property real discSpeed: 0
    readonly property real discTarget: MprisController.isPlaying ? 36 : 0
    // 30 fps is smooth for a slow 22 px disc; per-frame (120 Hz) updates cost ~15% CPU.
    property real discLast: 0
    Timer {
        interval: 33
        repeat: true
        running: root.animate && root.mode === "music" && (root.discSpeed > 0 || root.discTarget > 0)
        onRunningChanged: root.discLast = Date.now()
        onTriggered: {
            const t = Date.now();
            const dt = Math.min((t - root.discLast) / 1000, 0.1);
            root.discLast = t;
            const tau = root.discTarget > root.discSpeed ? 0.2 : 0.3; // spin-up ~0.6 s, coast ~0.9 s
            root.discSpeed += (root.discTarget - root.discSpeed) * (1 - Math.exp(-dt / tau));
            if (root.discTarget === 0 && root.discSpeed < 0.5)
                root.discSpeed = 0;
            root.discAngle = (root.discAngle + root.discSpeed * dt) % 360;
        }
    }

    // Cheap animation clock (~8 fps) for the logo, pulsing dots and clocks.
    // 15 fps only while an agent logo is moving: its light or zoom is too jumpy at 8.
    property int tick: 0
    onNowChanged: if (root.opencodeWorking) opencodeSweep.requestPaint()
    Timer {
        interval: ((root.opencodeWorking && root.mode === "opencode") || (root.claudeWorking && root.mode === "claude")) && root.animate ? 66 : 125
        repeat: true
        running: (root.claude || root.opencode || root.mode === "activity") && root.animate
        onTriggered: {
            root.tick++;
            root.now = Date.now();
        }
    }
    function opencodeText() {
        switch (root.opencodeState) {
        case "permission":
            return Translation.tr("OpenCode needs you");
        case "question":
            return Translation.tr("OpenCode asks you");
        case "retry": {
            const p = IslandState.opencodeLive?.payload ?? {};
            const left = Math.ceil(((p.retryAt ?? 0) - root.now) / 1000);
            // Only trust retryAt as a countdown when it is a sensible time in the future.
            if (left > 0 && left < 3600)
                return Translation.tr("Retrying in %1").arg(left >= 60 ? Math.floor(left / 60) + ":" + String(left % 60).padStart(2, "0") : left + "s");
            return (p.attempt ?? 0) > 1 ? Translation.tr("Retrying · try %1").arg(p.attempt) : Translation.tr("Retrying…");
        }
        case "compact":
            return Translation.tr("Compacting · %1").arg(root.clock());
        default:
            return Translation.tr("Building · %1").arg(root.clock());
        }
    }
    function clock() {
        const live = root.mode === "opencode" ? IslandState.opencodeLive : IslandState.live;
        const s = Math.max(0, Math.floor((root.now - (live?.createdAt ?? root.now)) / 1000));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    function pop() {
        popAnim.restart();
    }
    Connections {
        target: IslandState
        function onClaudeBurst(kind) {
            if (kind === "confetti") {
                root.celebrating = true;
                celebrateTimer.restart();
            }
            root.pop();
        }
        function onOpencodeBurst(kind) {
            if (kind === "confetti") {
                root.opencodeCelebrating = true;
                celebrateTimer.restart();
            }
            root.pop();
        }
    }
    Timer {
        id: celebrateTimer
        interval: 1300
        onTriggered: {
            root.celebrating = false;
            root.opencodeCelebrating = false;
        }
    }

    // Scroll over the resting island changes the output volume.
    WheelHandler {
        enabled: root.interactive
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const sink = Audio.sink;
            if (!sink?.audio)
                return;
            const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
            // Same steps as end-4's bar scroll (2%, 1% below 10%).
            IslandState.suppressOsdUntil = Date.now() + 600;
            if (d > 0)
                Audio.incrementVolume();
            else
                Audio.decrementVolume();
            const v = Math.max(0, Math.min(1, sink.audio.volume));
            IslandState.flash(v === 0 ? "volume_off" : v < 0.5 ? "volume_down" : "volume_up", Math.round(v * 100) + "%", { progress: v, ms: 1200 });
        }
    }

    // --- Flash / activity row -------------------------------------------------
    RowLayout {
        id: infoRow
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8
        visible: root.mode === "flash" || root.mode === "activity"
        transform: Translate { y: root.enterOffset }
        opacity: root.enterOpacity
        readonly property var item: root.mode === "flash" ? IslandState.flashItem : root.act
        readonly property color tint: (item?.color ?? "") !== "" ? item.color : Appearance.colors.colPrimary
        readonly property bool hasProgress: (item?.progress ?? -1) >= 0

        MaterialSymbol {
            text: infoRow.item?.icon ?? ""
            iconSize: 18
            fill: 1
            color: infoRow.tint
            // Recording-style dots pulse.
            opacity: root.mode === "activity" && (infoRow.item?.icon ?? "") === "radio_button_checked" ? 0.55 + 0.45 * Math.abs(Math.cos(root.tick * 0.35)) : 1
        }
        StyledText {
            Layout.fillWidth: !infoRow.hasProgress
            text: infoRow.item?.text ?? ""
            elide: Text.ElideRight
            font.pixelSize: infoRow.hasProgress ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
            color: infoRow.hasProgress ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
        }
        Rectangle {
            visible: infoRow.hasProgress
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Appearance.colors.colSecondaryContainer
            Rectangle {
                height: parent.height
                radius: 3
                width: parent.width * Math.max(0, Math.min(1, infoRow.item?.progress ?? 0))
                color: infoRow.tint
                Behavior on width { NumberAnimation { duration: 150 } }
            }
        }
    }

    // --- Claude / music row ---------------------------------------------------
    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: root.mode === "music" ? 6 : 12
        anchors.rightMargin: 10
        spacing: 8
        visible: root.showsSlot
        transform: Translate { y: root.enterOffset }
        opacity: root.enterOpacity

        AlbumArt {
            visible: root.mode === "music"
            size: 22
            source: MprisController.activeTrack?.artUrl ?? ""
            // Spins like a record: spins up on play, coasts to a stop on pause and
            // keeps its angle.
            rotation: root.discAngle
        }
        StyledText {
            Layout.fillWidth: true
            text: root.mode === "music"
                ? (IslandState.lyricLine || (MprisController.activeTrack?.title ?? ""))
                : (root.mode === "opencode" ? root.opencodeText()
                    : (root.waiting ? Translation.tr("Claude needs you") : Translation.tr("Working · %1").arg(root.clock())))
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.small
            font.italic: root.mode === "music" && IslandState.lyricLine !== ""
            // Waiting for permission is the one agent state that needs you: full-strength text.
            color: root.mode === "music" && !MprisController.isPlaying ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1
            font.weight: (root.mode === "claude" && root.waiting) || (root.mode === "opencode" && root.opencodeWaiting) ? Font.DemiBold : Font.Normal
        }

        Item {
            id: slot
            implicitWidth: 22
            implicitHeight: 22

            // Equaliser (real audio), tinted with the album colour.
            // Fixed height (the tallest a bar gets): sized to its bars, the centred row would
            // shift up and down with them.
            Row {
                anchors.centerIn: parent
                height: 14
                spacing: 2
                visible: !root.claude && !root.opencode
                Repeater {
                    model: 3
                    Rectangle {
                        id: bar
                        required property int index
                        width: 3
                        radius: 1.5
                        height: root.animate ? 4 + 10 * Math.min(1, IslandState.levels[bar.index] ?? 0) : 4 + 3 * (bar.index % 2)
                        anchors.bottom: parent.bottom
                        color: root.accent
                    }
                }
            }

            // Claude logo: zooms in and out while working, pulses while waiting for permission.
            Image {
                id: claudeLogo
                anchors.centerIn: parent
                visible: root.claude
                source: Qt.resolvedUrl("claude-logo.svg")
                sourceSize.width: 40
                sourceSize.height: 40
                width: 19
                height: 19
                smooth: true
                scale: root.claudeWorking ? 0.82 + 0.165 * (1 + Math.cos(root.now / 312)) : 1
                opacity: root.waiting ? 0.55 + 0.45 * Math.abs(Math.cos(root.tick * 0.4)) : 1
            }

            // Official OpenCode logo at its smallest allowed size (16x20, 4 px stroke), which
            // needs whole pixels to stay sharp. Pulses while waiting for permission.
            Image {
                id: opencodeLogo
                anchors.centerIn: parent
                visible: root.opencode && !root.opencodeWorking
                source: Qt.resolvedUrl("opencode-logo.svg")
                sourceSize.width: 16
                sourceSize.height: 20
                width: 16
                height: 20
                // Pulses while waiting for you; dimmed while a provider error waits for its retry.
                opacity: root.opencodeWaiting ? 0.55 + 0.45 * Math.abs(Math.cos(root.tick * 0.4))
                    : root.opencodeRetrying ? 0.45 : 1
            }

            // While working: the same logo with the ring dimmed and a band of light sweeping round it.
            Canvas {
                id: opencodeSweep
                anchors.centerIn: parent
                width: 16
                height: 20
                visible: root.opencodeWorking
                onVisibleChanged: if (visible) requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.scale(width / 240, height / 300);
                    ctx.fillStyle = "rgba(238, 238, 238, 0.28)";
                    ctx.fillRect(60, 120, 120, 120);
                    ctx.lineWidth = 60;
                    ctx.strokeStyle = "#57535a";
                    ctx.strokeRect(30, 30, 180, 240);
                    ctx.strokeStyle = "#5db4e0";
                    for (const segment of OpencodeLight.sweep((root.now % 1600) / 1600)) {
                        ctx.globalAlpha = segment.alpha;
                        ctx.beginPath();
                        ctx.moveTo(segment.points[0][0], segment.points[0][1]);
                        for (let i = 1; i < segment.points.length; i++)
                            ctx.lineTo(segment.points[i][0], segment.points[i][1]);
                        ctx.stroke();
                    }
                }
            }
            // "?" while waiting, "!" while OpenCode retries, otherwise the number of Claude sessions when more than one.
            Rectangle {
                visible: (root.claude && (root.waiting || IslandState.claudeSessions > 1)) || (root.opencode && (root.opencodeWaiting || root.opencodeRetrying))
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: -3
                width: 12
                height: 12
                radius: 6
                color: root.opencodeRetrying ? "#d29922" : root.opencode ? "#2d7fa5" : "#d97757"
                StyledText {
                    anchors.centerIn: parent
                    text: root.opencodeRetrying ? "!" : root.waiting || root.opencode ? "?" : IslandState.claudeSessions
                    color: "white"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }
            // Logo: click jumps to the terminal, hover shows what Claude has been doing.
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                enabled: root.claude && root.interactive
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.logoHovered(false); // focus moves to the terminal; a leave event may never come
                    IslandState.focusClaude();
                }
                onContainsMouseChanged: root.logoHovered(containsMouse)
            }

            SequentialAnimation {
                id: popAnim
                NumberAnimation { target: slot; property: "scale"; to: 1.6; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: slot; property: "scale"; to: 1; duration: 350; easing.type: Easing.OutBack }
            }
        }
    }

    // --- Idle: glance rotation (sliding), or a quiet bell -------------------------
    Ticker {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        visible: root.mode === "idle"
        center: true
        transform: Translate { y: root.enterOffset }
        opacity: root.enterOpacity
        key: root.glance ? root.glance.id : "bell"
        icon: root.glance ? root.glance.icon : (Notifications.silent ? "notifications_off" : "notifications")
        text: root.glance ? root.glance.text : ""
        graph: root.glance?.graph ?? []
        iconColor: root.glance ? ((root.glance.color ?? "") !== "" ? root.glance.color : Appearance.colors.colPrimary) : Appearance.colors.colSubtext
    }

    // --- Privacy dots (camera green, mic orange) on the left edge --------------
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        Rectangle {
            visible: IslandState.camDot
            width: 5
            height: 5
            radius: 2.5
            color: "#3fb950"
        }
        Rectangle {
            visible: IslandState.micDot
            width: 5
            height: 5
            radius: 2.5
            color: "#f0883e"
        }
    }
}
